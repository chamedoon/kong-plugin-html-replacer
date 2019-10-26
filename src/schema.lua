return {
    name = "html-replacer",
    fields = {
        { config = {
            type = "record",
            fields = {
                { search = {
                    type = "string",
                    required = false,
                  },
                },
                { replace_with = {
                    type = "string",
                    required = false,
                  },
                },
            },
          },
        },
    },
}
