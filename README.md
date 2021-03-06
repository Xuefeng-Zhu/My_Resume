## Overview
This repository contains my latest resume

## Credit
This project is based on [prat0318/json_resume](https://github.com/prat0318/json_resume)

##Installation

	$ gem install json_resume

### Conversion

* Syntax
`json_resume convert --template templates/default_html.mustache --out=html_pdf Xuefeng_Zhu_Resume.json`

```
    json_resume convert [--template=/path/to/custom/template]
                        [--out=html|html_pdf|tex|tex_pdf|md]
                        [--locale=es|en|pt]
                        [--theme=default|classic] <json_input>

    <json_input> can be /path/to/json OR "{'json':'string'}" OR http://raw.json
```

* Default (HTML) version

```
    $ json_resume convert prateek_cv.json
```

A directory `resume/` will be generated in cwd, which can be put hosted on /var/www or on github pages. ([Sample](http://prat0318.github.io/json_resume/html_version/resume_with_icons/))


* HTML\* version

`html` version without icons can be generated by giving `icons` as `false` : ([Sample](http://prat0318.github.io/json_resume/html_version/resume_without_icons/))

```
     "settings": {
         "icons" : false
    },
```

* PDF version from HTML ([Sample](http://prat0318.github.io/json_resume/html_version/resume_with_icons/resume.pdf))

```
    $ json_resume convert --out=html_pdf prateek_cv.json
```

* LaTeX version ([Sample](https://www.writelatex.com/read/ynhgbrnmtrbw))

```
    $ json_resume convert --out=tex prateek_cv.json
```

  LaTex also includes a ``classic`` theme. Usage: ``--theme=classic`` ([Sample](https://www.writelatex.com/read/xscbhfpxwkqh)).

* PDF version from LaTeX ([Sample](https://www.writelatex.com/read/ynhgbrnmtrbw))

```
    $ json_resume convert --out=tex_pdf prateek_cv.json
```

* Markdown version ([Sample](https://gist.github.com/prat0318/9c6e36fdcfd6a854f1f9))

```
    $ json_resume convert --out=md prateek_cv.json
```
