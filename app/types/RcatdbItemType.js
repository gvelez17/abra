var getEntityResolver = require('../util/entity-resolver');
var resolveMap = require('../resolve-map');
var GraphQL = require('graphql');
var GraphQLObjectType = GraphQL.GraphQLObjectType;
var GraphQLString = GraphQL.GraphQLString;
var GraphQLNonNull = GraphQL.GraphQLNonNull;
var GraphQLInt = GraphQL.GraphQLInt;
var getType = resolveMap.getType;
var registerType = resolveMap.registerType;

var RcatdbItemType = new GraphQLObjectType({
    name: 'RcatdbItem',
    description: '@TODO DESCRIBE ME',

    fields: function getRcatdbItemFields() {
        return {
            id: {
                type: new GraphQLNonNull(GraphQLString),
                description: '@TODO DESCRIBE ME'
            },

            cid: {
                type: new GraphQLNonNull(GraphQLString),
                description: '@TODO DESCRIBE ME'
            },

            name: {
                type: new GraphQLNonNull(GraphQLString),
                description: '@TODO DESCRIBE ME'
            },

            value: {
                type: new GraphQLNonNull(GraphQLString),
                description: '@TODO DESCRIBE ME'
            },

            qualifier: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            itemcode: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            owner: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            acl: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            entered: {
                type: new GraphQLNonNull(GraphQLInt),
                description: '@TODO DESCRIBE ME'
            },

            effectiveDate: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            url: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            shortContent: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            types: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            securityLevel: {
                type: GraphQLInt,
                description: '@TODO DESCRIBE ME'
            },

            rank: {
                type: GraphQLInt,
                description: '@TODO DESCRIBE ME'
            },

            hideFromFront: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            adfree: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            isFeed: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            wide: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            }
        };
    }
});

registerType(RcatdbItemType);
module.exports = RcatdbItemType;