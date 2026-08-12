## Overview
This repository contains my latest resume

## Credit
This project is based on [prat0318/json_resume](https://github.com/prat0318/json_resume)

## Local setup

Requirements: Ruby 2.6 or newer and Bundler.

```sh
bundle install --path vendor/bundle
bundle exec rake build
```

The generated resume is written to `resume/index.html`. It is self-contained
apart from the checked-in local assets, so it can be opened directly. To run a
local web server instead:

```sh
bundle exec rake serve
```

Then visit <http://127.0.0.1:8000>. Set `HOST` or `PORT` to override the
local server defaults.

Run the automated test suite with:

```sh
bundle exec rake
```

### Conversion

```text
bundle exec ruby bin/json_resume convert [--template=/path/to/custom/template]
                    [--out=html|html_pdf|tex|tex_pdf|md]
                    [--locale=es|en|pt]
                    [--theme=default|classic] <json_input>
```

`json_input` can be a local `.json` file, a raw JSON string, or an HTTP(S) URL.
Generate the default HTML version with:

```sh
bundle exec ruby bin/json_resume convert Xuefeng_Zhu_Resume.json
```

The command creates a complete `resume/index.html` and its local assets. Set
`settings.icons` to `false` in the input JSON to omit the icon stylesheet.

Generate a starter input file with:

```sh
bundle exec ruby bin/json_resume sample
```

Other output formats:

```sh
bundle exec ruby bin/json_resume convert --out=md Xuefeng_Zhu_Resume.json
bundle exec ruby bin/json_resume convert --out=tex Xuefeng_Zhu_Resume.json
bundle exec ruby bin/json_resume convert --out=tex --theme=classic Xuefeng_Zhu_Resume.json
```

PDF output requires system tooling that is intentionally not bundled:

- `--out=html_pdf` requires `wkhtmltopdf` on `PATH`.
- `--out=tex_pdf` requires `pdflatex`; the default theme also requires
  `kpsewhich` and the `moderncv` package.

When a PDF prerequisite is missing, the CLI exits with a setup message; the
plain HTML and TeX outputs remain available.
