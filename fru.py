# -*- coding: utf-8 -*-
# fru.py - Generate a binary IPMI FRU data file.

from __future__ import absolute_import
from __future__ import division
from __future__ import unicode_literals

import itertools
import os
import struct
import sys
import datetime
try:
    import configparser
except ImportError:
    import ConfigParser as configparser

try:
    FileNotFoundError
except NameError:
    FileNotFoundError = IOError


__version__ = '0.0.0'

EXTRAS = [
    'extra1', 'extra2', 'extra3',
    'extra4', 'extra5', 'extra6',
    'extra7', 'extra8', 'extra9',
]


def read_config(path):
    parser = configparser.ConfigParser()
    parser.read(path, encoding="utf-8")
    try:
        config = {
            section.decode('ascii'): {
                option.decode('ascii'): parser.get(section, option).strip('"')
                for option in parser.options(section)
            }
            for section in parser.sections()
        }
    except AttributeError:
        config = {
            section: {
                option: parser.get(section, option).strip('"')
                for option in parser.options(section)
            }
            for section in parser.sections()
        }

    integers = [
        ('common', 'size'),
        ('common', 'version'),
    ]

    hex_integers = [
        ('board', 'date'),
        ('board', 'language'),
        ('chassis', 'type'),
        ('product', 'language'),
    ]

    for section in ['internal', 'chassis', 'board', 'product', 'multirecord']:
        if config['common'].get(section, '0') != '1' and section in config:
            del(config[section])
        if section in config['common']:
            del(config['common'][section])

    for section, option in integers:
        if section in config and option in config[section]: 
            config[section][option] = int(config[section][option])

    for section, option in hex_integers:
        if section in config and option in config[section]:
            config[section][option] = int(config[section][option], 16)

    
    if config.get('internal', {}).get('data'):
        config['internal']['data'] = config['internal']['data'].encode('utf8')
    elif config.get('internal', {}).get('file'):
        internal_file = os.path.join(
            os.path.dirname(path), config['internal']['file']
        )
        try:
            with open(internal_file, 'rb') as f:
                config['internal']['data'] = f.read()
        except FileNotFoundError:
            message = 'Internal info area file {} not found.'
            raise ValueError(message.format(internal_file))
    if 'file' in config.get('internal', {}):
        del(config['internal']['file'])
    if 'internal' in config and not config['internal'].get('data'):
        del(config['internal'])

    return config


def validate_checksum(blob, offset, length):
    checksum = ord(blob[offset + length - 1:offset + length])
    data_sum = sum(
        struct.unpack('%dB' % (length - 1), blob[offset:offset + length - 1])
    )
    if 0xff & (data_sum + checksum) != 0:
        raise ValueError('The data does not match its checksum.')


def extract_values(blob, offset, names):
    data = {}

    extras = ('extra%d' % i for i in itertools.count(1)) 
    for name in itertools.chain(names, extras):  
        type_length = ord(blob[offset:offset + 1])
        if type_length == 0xc1:
            return data
        length = type_length & 0x3f
        # encoding = (ord(blob[offset:offset + 1]) & 0xc0) >> 6
        data[name] = blob[offset + 1:offset + length + 1].decode('ascii')
        offset += length + 1


def load(path=None, blob=None):
    if not path and not blob:
        raise ValueError('You must specify *path* or *blob*.')
    if path and blob:
        raise ValueError('You must specify *path* or *blob*, but not both.')

    if path:
        with open(path, 'rb') as f:
            blob = f.read()

    validate_checksum(blob, 0, 8)

    version = ord(blob[0:1])
    internal_offset = ord(blob[1:2]) * 8
    chassis_offset = ord(blob[2:3]) * 8
    board_offset = ord(blob[3:4]) * 8
    product_offset = ord(blob[4:5]) * 8

    data = {'common': {'version': version, 'size': len(blob)}}

    if internal_offset:
        next_offset = chassis_offset or board_offset or product_offset
        internal_blob = blob[internal_offset + 1:next_offset or len(blob)]
        data['internal'] = {'data': internal_blob}

    if chassis_offset:
        length = ord(blob[chassis_offset + 1:chassis_offset + 2]) * 8
        validate_checksum(blob, chassis_offset, length)

        data['chassis'] = {
            'type': ord(blob[chassis_offset + 2:chassis_offset + 3]),
        }
        names = ['part', 'serial']
        data['chassis'].update(extract_values(blob, chassis_offset + 3, names))

    if board_offset:
        length = ord(blob[board_offset + 1:board_offset + 2]) * 8
        validate_checksum(blob, board_offset, length)

        data['board'] = {
            'language': ord(blob[board_offset + 2:board_offset + 3]),
            'date': sum([
                ord(blob[board_offset + 3:board_offset + 4]),
                ord(blob[board_offset + 4:board_offset + 5]) << 8,
                ord(blob[board_offset + 5:board_offset + 6]) << 16,
            ]),
        }
        names = ['manufacturer', 'product', 'serial', 'part', 'fileid']
        data['board'].update(extract_values(blob, board_offset + 6, names))

    if product_offset:
        length = ord(blob[product_offset + 1:product_offset + 2]) * 8
        validate_checksum(blob, product_offset, length)

        data['product'] = {
            'language': ord(blob[product_offset + 2:product_offset + 3]),
        }
        names = [
            'manufacturer', 'product', 'part', 'version',
            'serial', 'asset', 'fileid',
        ]
        data['product'].update(extract_values(blob, product_offset + 3, names))

    return data


def dump(data):
    if 'common' not in data:
        raise ValueError('[common] section missing in config')

    if 'version' not in data['common']:
        raise ValueError('"version" missing in [common]')

    if 'size' not in data['common']:
        raise ValueError('"size" missing in [common]')

    internal_offset = 0
    chassis_offset = 0
    board_offset = 0
    product_offset = 0
    multirecord_offset = 0

    internal = bytes()
    chassis = bytes()
    board = bytes()
    product = bytes()

    if data.get('internal', {}).get('data'):
        internal = make_internal(data)
    if 'chassis' in data:
        chassis = make_chassis(data)
    if 'board' in data:
        board = make_board(data)
    if 'product' in data:
        product = make_product(data)

    pos = 1
    if len(internal):
        internal_offset = pos
        pos += len(internal) // 8
    if len(chassis):
        chassis_offset = pos
        pos += len(chassis) // 8
    if len(board):
        board_offset = pos
        pos += len(board) // 8
    if len(product):
        product_offset = pos

   
    out = struct.pack(
        'BBBBBBB',
        data['common'].get('version', 1),
        internal_offset,
        chassis_offset,
        board_offset,
        product_offset,
        multirecord_offset,
        0x00
    )

  
    out += struct.pack('B', (0 - sum(bytearray(out))) & 0xff)

    blob = out + internal + chassis + board + product
    difference = data['common']['size'] - len(blob)
    pad = struct.pack('B' * difference, *[0] * difference)

    if len(blob + pad) > data['common']['size']:
        raise ValueError('Too much content, does not fit')

    return blob + pad


def make_internal(data):
    return struct.pack(
        'B%ds' % len(data['internal']['data']),
        data['common'].get('version', 1),
        data['internal']['data'],
    )


def make_chassis(config):
    out = bytes()

    
    out += struct.pack('B', config['chassis'].get('type', 0))

   
    fields = ['part', 'serial']

    
    max_extra = max([
        int(key[5:])
        for key in config['chassis']
        if key.startswith('extra')
    ] or [0])
    if max_extra:
        fields.extend(['extra{}'.format(i) for i in range(1, max_extra + 1)])

    for k in fields:
        if config['chassis'].get(k):
            value = config['chassis'][k].encode('ascii')
            out += struct.pack('B%ds' % len(value), len(value) | 0xC0, value)
        else:
            out += struct.pack('B', 0)

    
    out += struct.pack('B', 0xC1)

  
    while len(out) % 8 != 5:
        out += struct.pack('B', 0)

    
    out = struct.pack(
        'BB',
        config['common'].get('version', 1),
        (len(out) + 3) // 8,
    ) + out

    
    out += struct.pack('B', (0 - sum(bytearray(out))) & 0xff)

    return out

def minNums(startTime, endTime):
    startTime1 = startTime + ':00'
    endTime1 = endTime + ':00'
    startTime2 = datetime.datetime.strptime(startTime1, "%Y-%m-%d %H:%M:%S")
    endTime2 = datetime.datetime.strptime(endTime1, "%Y-%m-%d %H:%M:%S")
    seconds = (endTime2 - startTime2).seconds
    total_seconds = (endTime2 - startTime2).total_seconds()
    mins = total_seconds / 60
    return int(mins)

def make_board(config):
    out = bytes()

    
    out += struct.pack('B', config['board'].get('language', 0))

    
    date = config['board'].get('date', 0)
    hexdate = hex(date)
    str = format(hexdate)
    str = str.replace('0x','')
   
    if 12 != len(str):
        print('[board] date format is incorrect')
        sys.exit()   
    else:
        list_str = list(str)
        list_str.insert(4,'-')
        list_str.insert(7,'-')
        list_str.insert(10,' ')
        list_str.insert(13,':')
        str = ''.join(list_str)
        date = minNums('1996-01-01 08:00',str)
        out += struct.pack(
            'BBB',
            (date & 0xFF),
            (date & 0xFF00) >> 8,
            (date & 0xFF0000) >> 16,
    )

    
    fields = ['manufacturer', 'product', 'serial', 'part', 'fileid']

    
    max_extra = max([
        int(key[5:])
        for key in config['board']
        if key.startswith('extra')
    ] or [0])
    if max_extra:
        fields.extend(['extra{}'.format(i) for i in range(1, max_extra + 1)])

    for key in fields:
        if config['board'].get(key):
            value = config['board'][key].encode('ascii')
            out += struct.pack('B%ds' % len(value), len(value) | 0xC0, value)
        else:
            out += struct.pack('B', 0)

   
    out += struct.pack('B', 0xC1)

   
    while len(out) % 8 != 5:
        out += struct.pack('B', 0)

    
    out = struct.pack(
        'BB',
        config['common'].get('version', 1),
        (len(out)+3) // 8,
    ) + out

    
    out += struct.pack('B', (0 - sum(bytearray(out))) & 0xff)

    return out


def make_product(config):
    out = bytes()

    
    out += struct.pack('B', config['product'].get('language', 0))

    
    fields = [
        'manufacturer', 'product', 'part', 'version', 'serial', 'asset',
        'fileid',
    ]

   
    max_extra = max([
        int(key[5:])
        for key in config['product']
        if key.startswith('extra')
    ] or [0])
    if max_extra:
        fields.extend(['extra{}'.format(i) for i in range(1, max_extra + 1)])

    for key in fields:
        if config['product'].get(key):
            value = config['product'][key].encode('ascii')
            out += struct.pack('B%ds' % len(value), len(value) | 0xC0, value)
        else:
            out += struct.pack('B', 0)

   
    out += struct.pack('B', 0xC1)

   
    while len(out) % 8 != 5:
        out += struct.pack('B', 0)

    
    out = struct.pack(
        'BB',
        config['common'].get('version', 1),
        (len(out) + 3) // 8,
    ) + out

   
    out += struct.pack('B', (0 - sum(bytearray(out))) & 0xff)

    return out


def run(ini_file, bin_file):  
    try:
        configuration = read_config(ini_file)
        blob = dump(configuration)
    except ValueError as error:
        print(error.message)
    else:
        with open(bin_file, 'wb') as f:
            f.write(blob)
            print('%s created success!' % sys.argv[2])

if __name__ == '__main__':  
    if len(sys.argv) < 3:
        print('fru.py input.ini output.bin [--force] [--cmd]')
        sys.exit()

    if not os.path.exists(sys.argv[1]):
        print('Missing INI file %s' % sys.argv[1])
        sys.exit()

    if os.path.exists(sys.argv[2]) and '--force' not in sys.argv:
        print('BIN file %s exists' % sys.argv[2])
        sys.exit()

    run(sys.argv[1], sys.argv[2])
