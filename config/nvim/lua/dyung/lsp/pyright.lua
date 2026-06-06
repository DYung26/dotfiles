return {
  single_file_support = false, -- optional: faster for multi-buffer sessions
  settings = {
    python = {
      pythonpath = os.getenv("virtual_env") and (os.getenv("virtual_env") .. "/scripts/python.exe") or "python",
      venvpath = ".",
      venv = "venv",
      analysis = {
        -- exclude large or irrelevant directories from indexing
        exclude = {
          "**/node_modules",
          "**/__pycache__",
          "**/.venv",
          "**/venv",
          "**/build",
          "**/dist",
          "**/*.ipynb"  -- optional: exclude notebooks
        },
        pythonversion = "3.10",
        reportmissingimports = false,
        reportmissingtypestubs = false,
        uselibrarycodefortypes = true,
        autosearchpaths = true,
        extrapaths = { "c:/users/oyeku/plotkit" },
        diagnosticmode = "openfilesonly",
      },
    },
  },
}
