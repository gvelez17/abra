var getEntityResolver = require('../util/entity-resolver');
var resolveMap = require('../resolve-map');
var GraphQL = require('graphql');
var GraphQLObjectType = GraphQL.GraphQLObjectType;
var GraphQLString = GraphQL.GraphQLString;
var GraphQLNonNull = GraphQL.GraphQLNonNull;
var GraphQLInt = GraphQL.GraphQLInt;
var getType = resolveMap.getType;
var registerType = resolveMap.registerType;

var RcatdbCategoryType = new GraphQLObjectType({
    name: 'RcatdbCategory',
    description: '@TODO DESCRIBE ME',

    fields: function getRcatdbCategoryFields() {
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

            relUrl: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            catcode: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            lastsubcode: {
                type: GraphQLInt,
                description: '@TODO DESCRIBE ME'
            },

            owner: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            entered: {
                type: new GraphQLNonNull(GraphQLInt),
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

            displayOrder: {
                type: GraphQLInt,
                description: '@TODO DESCRIBE ME'
            },

            externalUri: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            }
        };
    }
});

registerType(RcatdbCategoryType);
module.exports = RcatdbCategoryType;