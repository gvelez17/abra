var getEntityResolver = require('../util/entity-resolver');
var resolveMap = require('../resolve-map');
var GraphQL = require('graphql');
var GraphQLObjectType = GraphQL.GraphQLObjectType;
var GraphQLString = GraphQL.GraphQLString;
var getType = resolveMap.getType;
var registerType = resolveMap.registerType;

var RelatedcontentType = new GraphQLObjectType({
    name: 'Relatedcontent',
    description: '@TODO DESCRIBE ME',

    fields: function getRelatedcontentFields() {
        return {
            uid: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            text: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            },

            acl: {
                type: GraphQLString,
                description: '@TODO DESCRIBE ME'
            }
        };
    }
});

registerType(RelatedcontentType);
module.exports = RelatedcontentType;