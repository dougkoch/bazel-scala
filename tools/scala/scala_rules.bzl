def build_jar(ctx, jar):
  sources = []
  for dep in ctx.attr.deps:
    for source in dep.files:
      sources += [source]

  ctx.action(
    inputs=sources,
    outputs=[jar],
    command="scalac %s -d %s"
        % (' '.join(["%s" % src.path for src in sources]), jar.path)
  )

def scala_binary_impl(ctx):
  final_jar = ctx.outputs.out
  intermediate_jar = ctx.new_file(ctx.configuration.bin_dir, "intermediate.jar")

  # 1st action is to build the jar
  build_jar(ctx, intermediate_jar)

  # 2nd action is to update the jar manifest
  ctx.action(
    inputs=[intermediate_jar],
    outputs=[final_jar],
    command=("mv %s %s && " +
        "cp /usr/share/java/scala-library.jar . && " +
        "echo \"Class-Path: scala-library.jar\n\" > manifest.txt && " +
        "jar ufvm %s manifest.txt scala-library.jar")
        % (intermediate_jar.path, final_jar.path, final_jar.path)
  )

def scala_library_impl(ctx):
  build_jar(ctx, ctx.outputs.out)

scala_binary = rule(
  implementation = scala_binary_impl,
  attrs = {
    "deps": attr.label_list(allow_files=True),
  },
  outputs = {
    "out": "%{name}.jar"
  }
)

scala_library = rule(
  implementation = scala_library_impl,
  attrs = {
    "deps": attr.label_list(allow_files=True)
  },
  outputs = {
    "out": "%{name}.jar"
  }
)
