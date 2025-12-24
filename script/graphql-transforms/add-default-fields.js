import { readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { Kind, parse, print, visit } from 'graphql'

const DEFAULT_FIELDS = new Set([
  'content_id',
  'title',
  'locale',
  'analytics_identifier',
  'api_path',
  'base_path',
  'document_type',
  'public_updated_at',
  'schema_name',
  'api_url',
  'web_url',
])

const fragmentDefinition = {
  kind: Kind.FRAGMENT_DEFINITION,
  name: { kind: Kind.NAME, value: 'defaultFields' },
  typeCondition: {
    kind: Kind.NAMED_TYPE,
    name: { kind: Kind.NAME, value: 'Edition' },
  },
  selectionSet: {
    kind: Kind.SELECTION_SET,
    selections: [...DEFAULT_FIELDS].map((f) => ({
      kind: Kind.FIELD,
      name: { kind: Kind.NAME, value: f },
    })),
  },
}

const fragmentSpread = {
  kind: Kind.FRAGMENT_SPREAD,
  name: { kind: Kind.NAME, value: 'defaultFields' },
}

function addDefaultFieldsFragments(ast) {
  let alreadyHadDefaultFieldsFragment = false
  let usedDefaultFieldsFragment = false
  return visit(ast, {
    SelectionSet(node, key, parent) {
      if (parent.kind !== Kind.FIELD) {
        return
      }

      const fields = new Set(
        node.selections
          .filter((f) => f.kind === Kind.FIELD)
          .map((f) => f.name.value),
      )

      if (fields.isSupersetOf(DEFAULT_FIELDS)) {
        usedDefaultFieldsFragment = true

        const remainder = node.selections.filter(
          (f) => !DEFAULT_FIELDS.has(f.name.value),
        )
        return { ...node, selections: [fragmentSpread, ...remainder] }
      }
    },

    Document: {
      enter(node) {
        if (
          node.definitions.some(
            (d) =>
              d.kind === Kind.FRAGMENT_DEFINITION &&
              d.name.value === 'defaultFields',
          )
        ) {
          alreadyHadDefaultFieldsFragment = true
        }
      },
      leave(node) {
        if (usedDefaultFieldsFragment && !alreadyHadDefaultFieldsFragment) {
          return {
            ...node,
            definitions: [fragmentDefinition, ...node.definitions],
          }
        }
      },
    },
  })
}

const queriesDir = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../app/graphql/queries',
)
readdirSync(queriesDir).forEach((file) => {
  const filePath = path.join(queriesDir, file)
  const ast = parse(readFileSync(filePath, 'utf-8'))
  const editedAst = addDefaultFieldsFragments(ast)
  writeFileSync(filePath, print(editedAst))
})
