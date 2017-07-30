var getEntityResolver = require('../util/entity-resolver');
var resolveMap = require('../resolve-map');
var GraphQL = require('graphql');
var GraphQLObjectType = GraphQL.GraphQLObjectType;
var GraphQLString = GraphQL.GraphQLString;
var GraphQLFloat = GraphQL.GraphQLFloat;
var getType = resolveMap.getType;
var registerType = resolveMap.registerType;

var AbBizOrgType = new GraphQLObjectType({
    name: 'AbBizOrg',
    description: '@TODO DESCRIBE ME',

    fields: function getAbBizOrgFields() {
        return {
            id: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            addr: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            zip: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            phone: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            email: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            city: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            zip4: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            localOwnop: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            lat: {
                type: GraphQLFloat,
                description: '@TODO DESCRIBE ME'
            },

            blong: {
                type: GraphQLFloat,
                description: '@TODO DESCRIBE ME'
            }
        };
    }
});

registerType(AbBizOrgType);
module.exports = AbBizOrgType;