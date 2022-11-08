{
  absolute_path: {
    type: "string",
    pattern: "^/(([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})+(/([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})*)*)?$",
    description: "A path only. Query string and/or fragment are not allowed.",
  },
  absolute_fullpath: {
    type: "string",
    pattern: "^/(([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})+(/([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})*)*)?(\\?([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})*)?(#([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})*)?$",
    description: "A path with optional query string and/or fragment.",
  },
  absolute_path_optional: {
    anyOf: [
      {
        "$ref": "#/definitions/absolute_path",
      },
      {
        type: "null",
      },
    ],
  },
}
