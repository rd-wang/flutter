pub :https://pub.dev/packages/dcdg
repo:https://github.com/glesica/dcdg.dart

Usage: dcdg [options]

    -b, --builder=<NAME>            用于构造类图的构建器（默认为“plantuml”）
    -e, --exclude=<TYPE>            要排除的类类型名称，可以是正则表达式
        --exclude-private=<KIND>    排除私有实体（字段、方法、类或全部）
        --exclude-has-a             从图表输出中排除 has-a 聚合关系
        --exclude-is-a              从图表输出中排除 is-a 扩展关系
        --exported-only             仅包含从 Dart 包导出的类
        --has-a=<CLASS>             仅包含与任何具有 has-a 关系的类命名类的
        --is-a=<CLASS>              仅包含与任何命名类具有 is-a 关系的类
    -h, --help                      显示使用信息
    -V, --verbose                   显示详细输出
    -i, --include=<TYPE>            要包含的类类型名称，可以是正则表达式
    -o, --output=<FILE>             应写入输出的文件（如果省略则为 stdout）（默认为“”）
    -p, --package=<DIR>             要扫描的 Dart 包根目录的路径（默认为“.”）
    -s, --search-path=<DIR>         相对于包根目录搜索类的目录（默认为“lib” )
    -v, --version                   显示版本号并退出
ex:
fvm dart pub global run dcdg --exported-only --exclude-has-a --exclude-is-a  -o puml/binding.puml

Available builders:
  * plantuml - PlantUML 构建器试图实现功能完整
  * dot - 仅处理继承的 Graphviz 构建器
  * nomnoml - 用于在网页中嵌入图表的 Nomnoml 构建器
  * mermaid - mermaid builder that attempts to be feature-complete

The --include, --exclude, --has-a, and --is-a
options accept regular expressions. These options accept multiple values,
separated by commas, or they can be passed multiple times.

Note: If both exclude and include are supplied, types that
are in both lists will be removed from the includes list and then the
includes list will be applied as usual.