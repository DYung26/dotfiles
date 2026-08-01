return {
  single_file_support = false,

  settings = {
    typescript = {
      tsserver = {
        maxTsServerMemory = 4096,
      },
    },
    vtsls = {
      autoUseWorkspaceTsdk = true,
      experimental = {
        maxInlayHintLength = 30,
      },
    },
  },
}
