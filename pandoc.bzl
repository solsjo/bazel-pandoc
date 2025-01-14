PANDOC_EXTENSIONS = {
    "asciidoc": "adoc",
    "beamer": "tex",
    "commonmark": "md",
    "context": "tex",
    "docbook": "xml",
    "docbook4": "xml",
    "docbook5": "xml",
    "docx": "docx",
    "dokuwiki": "txt",
    "dzslides": "html",
    "epub": "epub",
    "epub2": "epub",
    "epub3": "epub",
    "fb2": "fb",
    "haddock": "txt",
    "html": "html",
    "html4": "html",
    "html5": "html",
    "icml": "icml",
    "jats": "xml",
    "json": "json",
    "latex": "tex",
    "man": "1",
    "markdown": "md",
    "markdown_github": "md",
    "markdown_mmd": "md",
    "markdown_phpextra": "md",
    "markdown_strict": "md",
    "mediawiki": "txt",
    "ms": "1",
    "muse": "txt",
    "native": "txt",
    "odt": "odt",
    "opendocument": "odt",
    "opml": "openml",
    "org": "txt",
    "plain": "txt",
    "pptx": "pptx",
    "revealjs": "html",
    "rst": "rst",
    "rtf": "rtf",
    "s5": "html",
    "slideous": "html",
    "slidy": "html",
    "tei": "html",
    "texinfo": "texi",
    "textile": "textile",
    "zimwiki": "txt",
}

def _pandoc_impl(ctx):
    toolchain = ctx.toolchains["@bazel_pandoc//:pandoc_toolchain_type"]
    inputs = [ctx.file.src] + ctx.files.data + ctx.files.filters
    cli_args = []
    filters = []
    pandoc_inputs = []
    data_inputs = []
    data_outputs = []
    for filter in ctx.attr.filters:
        filt = ctx.expand_location("$(locations {})".format(filter.label), ctx.attr.filters).split(" ")[0]
        filters.extend(["--filter", filt])
    cli_args.extend(filters)
    if ctx.attr.from_format:
        cli_args.extend(["--from", ctx.attr.from_format])
    if ctx.attr.to_format:
        cli_args.extend(["--to", ctx.attr.to_format])
    cli_args.extend(["-o", ctx.outputs.output.path])
    cli_args.extend([ctx.file.src.path])
    env = {}
    for k,v in ctx.attr.env.items():
        if "$(location" in v or "$(execpath" in v or "$(rootpath" in v:
            env[k] = ctx.expand_location(v, ctx.attr.data).split(" ")[0]
        else:
            env[k] = v

    tools = []
    
    for filter in ctx.attr.filters:
        if filter[DefaultInfo].files_to_run:
            tools.append(filter[DefaultInfo].files_to_run)
        tools.extend(filter[DefaultInfo].files.to_list())

    for dat in ctx.attr.data:
        if dat[DefaultInfo].files_to_run:
            tools.append(dat[DefaultInfo].files_to_run)
            tools.extend(dat[DefaultInfo].files.to_list())

    self_contained = False
    resource_paths = []
    for opt in ctx.attr.options:
        if "self-contained" in opt:
            self_contained = True
    for target in ctx.attr.data:
        for df in target.files.to_list():
            if self_contained:
                pandoc_inputs.append(df)
                resource_paths.append(df.dirname)
            else:
                data_inputs.append(df)
                resource_paths.append(df.dirname)
                
                
    for df in data_inputs:
        outfile = ctx.actions.declare_file("gen_" + df.basename)
        data_outputs.extend([outfile])
        ctx.actions.expand_template(template=df,
                                    output = outfile,
                                    substitutions={})
    for inp in inputs:
        resource_paths.append(inp.dirname)
    cli_args.extend(["--resource-path",
                      ".:" + "external" + ":" + ctx.label.package + ":" + ":".join(resource_paths)])
    cli_args.extend([ctx.expand_location(opt, ctx.attr.data) for opt in ctx.attr.options])

    print(cli_args)
    
    ctx.actions.run(
        mnemonic = "Pandoc",
        executable = toolchain.pandoc.files.to_list()[0].path,
        arguments = cli_args,
        inputs = depset(
            direct = pandoc_inputs + inputs,
            transitive = [toolchain.pandoc.files] + 
                [dat[DefaultInfo].files for dat in ctx.attr.data]
        ),
        tools = tools,
        env = env,
        outputs = [ctx.outputs.output],
    )
    return [
         DefaultInfo(files = depset([ctx.outputs.output] + data_outputs ),
         runfiles = ctx.runfiles(files=data_outputs))
     ]

_pandoc = rule(
    attrs = {
        "from_format": attr.string(),
        "options": attr.string_list(),
        "src": attr.label(allow_single_file = True, mandatory = True),
        "to_format": attr.string(),
        "output": attr.output(mandatory = True),
        "data": attr.label_list(mandatory = False, allow_files=True),
        "filters": attr.label_list(mandatory = False),
        "env": attr.string_dict(),
    },
    toolchains = ["@bazel_pandoc//:pandoc_toolchain_type"],
    implementation = _pandoc_impl,
)

def _check_format(format, attr_name):
    if format not in PANDOC_EXTENSIONS:
        fail("Unknown `%{attr}` format: %{format}".fmt(attr = attr_name, format = format))
    return format

def _infer_output(name, to_format):
    """Derives output file based on the desired format.

    Use the generic .xml syntax for XML-based formats and .txt for
    ones with no commonly used extension.
    """
    to_format = _check_format(to_format, "to_format")
    ext = PANDOC_EXTENSIONS[to_format]
    return name + "." + ext

def pandoc(**kwargs):
    if "output" not in kwargs:
        if "to_format" not in kwargs:
            fail("One of `output` or `to_format` attributes must be provided")
        to_format = _check_format(kwargs["to_format"], "to_format")
        kwargs["output"] = _infer_output(kwargs["name"], to_format)
    _pandoc(**kwargs)
