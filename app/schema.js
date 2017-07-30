'use strict';
var getEntityResolver = require('./util/entity-resolver');
var GraphQL = require('graphql');
var AbBizOrgType = require('./types/AbBizOrgType');
var RcatdbCategoryType = require('./types/RcatdbCategoryType');
var RcatdbItemType = require('./types/RcatdbItemType');
var RcatdbRitemType = require('./types/RcatdbRitemType');
var RcatdbRcatType = require('./types/RcatdbRcatType');
var RelatedcontentType = require('./types/RelatedcontentType');
var resolveMap = require('./resolve-map');
var types = require('./types');
var GraphQLObjectType = GraphQL.GraphQLObjectType;
var GraphQLSchema = GraphQL.GraphQLSchema;
var GraphQLNonNull = GraphQL.GraphQLNonNull;
var GraphQLString = GraphQL.GraphQLString;
var registerType = resolveMap.registerType;

var schema = new GraphQLSchema({
    query: new GraphQLObjectType({
        name: 'RootQueryType',

        fields: function getRootQueryFields() {
            return {
                abBizOrg: {
                    type: AbBizOrgType,
                    args: {},
                    resolve: getEntityResolver('AbBizOrg')
                },

                rcatdbCategory: {
                    type: RcatdbCategoryType,

                    args: {
                        id: {
                            name: 'id',
                            type: new GraphQLNonNull(GraphQLString)
                        }
                    },

                    resolve: getEntityResolver('RcatdbCategory')
                },

                rcatdbItem: {
                    type: RcatdbItemType,

                    args: {
                        id: {
                            name: 'id',
                            type: new GraphQLNonNull(GraphQLString)
                        }
                    },

                    resolve: getEntityResolver('RcatdbItem')
                },

                rcatdbRitem: {
                    type: RcatdbRitemType,
                    args: {},
                    resolve: getEntityResolver('RcatdbRitem')
                },

                rcatdbRcat: {
                    type: RcatdbRcatType,
                    args: {},
                    resolve: getEntityResolver('RcatdbRcat')
                },

                relatedcontent: {
                    type: RelatedcontentType,
                    args: {},
                    resolve: getEntityResolver('Relatedcontent')
                }
            };
        }
    })
});

module.exports = schema;