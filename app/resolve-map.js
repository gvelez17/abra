'use strict';

var resolveMap = {
    'AbBizOrg': {
        'name': 'AbBizOrg',
        'table': 'ab_biz_org',
        'primaryKey': null,

        'aliases': {
            'local_ownop': 'localOwnop'
        },

        'referenceMap': {},
        'listReferences': {}
    },

    'RcatdbCategory': {
        'name': 'RcatdbCategory',
        'table': 'rcatdb_categories',
        'primaryKey': 'ID',

        'aliases': {
            'ID': 'id',
            'CID': 'cid',
            'NAME': 'name',
            'REL_URL': 'relUrl',
            'ENTERED': 'entered',
            'security_level': 'securityLevel',
            'display_order': 'displayOrder',
            'external_uri': 'externalUri'
        },

        'referenceMap': {},
        'listReferences': {}
    },

    'RcatdbItem': {
        'name': 'RcatdbItem',
        'table': 'rcatdb_items',
        'primaryKey': 'ID',

        'aliases': {
            'ID': 'id',
            'CID': 'cid',
            'NAME': 'name',
            'VALUE': 'value',
            'QUALIFIER': 'qualifier',
            'ENTERED': 'entered',
            'effective_date': 'effectiveDate',
            'URL': 'url',
            'short_content': 'shortContent',
            'TYPES': 'types',
            'security_level': 'securityLevel',
            'hide_from_front': 'hideFromFront',
            'is_feed': 'isFeed'
        },

        'referenceMap': {},
        'listReferences': {}
    },

    'RcatdbRitem': {
        'name': 'RcatdbRitem',
        'table': 'rcatdb_ritems',
        'primaryKey': null,

        'aliases': {
            'UID': 'id',
            'ID': 'id',
            'RELATION': 'relation',
            'CAT_DEST': 'catDest',
            'ITEM_DEST': 'itemDest',
            'QUALIFIER': 'qualifier',
            'ENTERED': 'entered'
        },

        'referenceMap': {},
        'listReferences': {}
    },

    'RcatdbRcat': {
        'name': 'RcatdbRcat',
        'table': 'rcatdb_rcats',
        'primaryKey': null,

        'aliases': {
            'UID': 'id',
            'ID': 'id',
            'RELATION': 'relation',
            'CAT_DEST': 'catDest',
            'ITEM_DEST': 'itemDest',
            'QUALIFIER': 'qualifier',
            'ENTERED': 'entered'
        },

        'referenceMap': {},
        'listReferences': {}
    },

    'Relatedcontent': {
        'name': 'Relatedcontent',
        'table': 'relatedcontent',
        'primaryKey': null,
        'aliases': {},
        'referenceMap': {},
        'listReferences': {}
    }
};

exports.resolveMap = resolveMap;

exports.registerType = function registerType(type) {
    if (!resolveMap[type.name]) {
        throw new Error(
            'Cannot register type "' + type.name + '" - resolve map does not exist for that type'
        );
    }

    resolveMap[type.name].type = type;
};

exports.getType = function getType(type) {
    if (!resolveMap[type] || !resolveMap[type].type) {
        throw new Error('No type registered for type \'' + type + '\'');
    }

    return resolveMap[type].type;
};