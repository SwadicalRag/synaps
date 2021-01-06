import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:source_gen/source_gen.dart";
import "package:build/build.dart";
import "package:synaps/src/annotations.dart";

Type typeOf<T>() => T;

class ObservableGenerator extends GeneratorForAnnotation<Controller> {
  void _checkAnnotationInternal<T>(FieldElement element,Map<Type,DartObject> out) {
    final annotations =
        TypeChecker.fromRuntime(T).annotationsOf(element);
    if (annotations.isNotEmpty) {
      out[typeOf<T>()]  = annotations.first;
    }
  }

  Map<Type,DartObject> getFieldAnnotations(FieldElement element) {
    final out = <Type,DartObject>{};

    _checkAnnotationInternal<Observable>(element, out);

    return out;
  }

  @override
  String generateForAnnotatedElement(Element element, 
      ConstantReader classAnnotation, BuildStep buildStep) {
    
    if (element is ClassElement && !element.isEnum) {
      final buffer = StringBuffer();

      final parentClassName = element.displayName;
      final classNamePublic = parentClassName + "Controller";
      final className = "_" + classNamePublic;
      final templateDeclarations = element.typeParameters.isNotEmpty ?
        "<" + element.typeParameters.map((t) => t.getDisplayString(withNullability: false)).join(",") + ">"
          : "";
      final templates = element.typeParameters.isNotEmpty ?
        "<" + element.typeParameters.map((t) => t.name).join(",") + ">"
          : "";

      buffer.write("class ${className}${templateDeclarations} ");
      if(element.supertype != null) {
        buffer.write("extends ${element.supertype.getDisplayString(withNullability: false)} ");
      }
      if(element.mixins.isNotEmpty) {
        final mixinList = element.mixins.map((mxn) => mxn.getDisplayString(withNullability: false)).join(",");

        buffer.write("with ControllerInterface,${mixinList} ");
      }
      else {
        buffer.write("with ControllerInterface ");
      }
      buffer.writeln("implements ${parentClassName}${templates} {");
      buffer.writeln("final ${parentClassName}${templates} _internal;");

      final copyOnInitialise = <String,String>{};
      final copyOnInitialiseType = <String,String>{};

      void forwardField(FieldElement field) {
        final fieldAnnotations = getFieldAnnotations(field);

        for (final fieldAnnotationType in fieldAnnotations.keys) {
          switch(fieldAnnotationType) {
            default: {
              break;
            }
          }
        }

        if(fieldAnnotations.containsKey(Observable)) {
          final annotation = fieldAnnotations[Observable];

          if(field.type.isDartCoreList) {
            final proxyName = "_proxy_${field.name}";
            final typeString = field.type.getDisplayString(withNullability: false);
            final proxyTypeString = "Synaps" + typeString;

            copyOnInitialise[field.name] = proxyName;
            copyOnInitialiseType[field.name] = proxyTypeString;

            buffer.writeln("${proxyTypeString} ${proxyName};");
            buffer.writeln("@override");
            buffer.writeln("${proxyTypeString} get ${field.name} {");
            buffer.writeln("synapsMarkVariableRead(#${field.name});");
            buffer.writeln("return ${proxyName};");
            buffer.writeln("}");

            buffer.writeln("@override");
            buffer.writeln("set ${field.name}(${typeString} value) {");
            buffer.writeln("_internal.${field.name} = value;");
            buffer.writeln("synapsMarkVariableDirty(#${field.name},value);");
            buffer.writeln("}");
          }
          else {
            final typeString = field.type.getDisplayString(withNullability: false);

            buffer.writeln("@override");
            buffer.writeln("${typeString} get ${field.name} {");
            buffer.writeln("synapsMarkVariableRead(#${field.name});");
            buffer.writeln("return _internal.${field.name};");
            buffer.writeln("}");

            buffer.writeln("@override");
            buffer.writeln("set ${field.name}(${typeString} value) {");
            buffer.writeln("_internal.${field.name} = value;");
            buffer.writeln("synapsMarkVariableDirty(#${field.name},value);");
            buffer.writeln("}");
          }
        }
        else {
          final typeString = field.type.getDisplayString(withNullability: false);

          buffer.writeln("@override");
          buffer.writeln("${typeString} get ${field.name} {");
          buffer.writeln("return _internal.${field.name};");
          buffer.writeln("}");

          buffer.writeln("@override");
          buffer.writeln("set ${field.name}(${typeString} value) {");
          buffer.writeln("_internal.${field.name} = value;");
          buffer.writeln("}");
        }
      }

      void forwardMethod(MethodElement method) {
        final returnTypeString = method.returnType.getDisplayString(withNullability: false);
        final functionTemplates = method.typeParameters.isNotEmpty ?
          "<" + method.typeParameters.map((t) => t.name).join(",") + ">"
            : "";

        var argListDeclarations = "";
        var argList = "";
        
        final numPositionalArgs = method.parameters
          .fold(0,(val,param) => val + (param.isRequiredPositional ? 1 : 0));
        final hasOptionalPositional = method.parameters
          .fold(false,(val,param) => val || param.isOptionalPositional);
        final hasNamed = method.parameters
          .fold(false,(val,param) => val || param.isNamed);
        
        // Generate all argument declarations
        argListDeclarations += method.parameters.where((param) => param.isRequiredPositional).map((param) {
          return param.type.getDisplayString(withNullability: false)
            + " " + param.name;
        }).join(",");

        if(hasOptionalPositional) {
          if(numPositionalArgs > 0) {
            argListDeclarations += ",";
          }

          argListDeclarations += "[";
          
          argListDeclarations += method.parameters.where((param) => param.isOptionalPositional).map((param) {
            return param.type.getDisplayString(withNullability: false)
              + " " + param.name;
          }).join(",");

          argListDeclarations += "]";
        }
        else if(hasNamed) {
          if(numPositionalArgs > 0) {
            argListDeclarations += ",";
          }

          argListDeclarations += "{";
          
          argListDeclarations += method.parameters.where((param) => param.isNamed).map((param) {
            var cParam = param.type.getDisplayString(withNullability: false)
              + " " + param.name;

            if(param.hasRequired) {
              cParam = "@required " + cParam;
            }

            return cParam;
          }).join(",");

          argListDeclarations += "}";
        }
        
        // Generate all argument expressions
        argList += method.parameters.where((param) => param.isRequiredPositional).map((param) {
          return param.name;
        }).join(",");

        if(hasOptionalPositional) {
          if(numPositionalArgs > 0) {
            argList += ",";
          }

          argList += method.parameters.where((param) => param.isOptionalPositional).map((param) {
            return param.name;
          }).join(",");
        }
        else if(hasNamed) {
          if(numPositionalArgs > 0) {
            argList += ",";
          }

          argList += method.parameters.where((param) => param.isNamed).map((param) {
            return param.name + ": " + param.name;
          }).join(",");
        }

        buffer.writeln("@override");
        buffer.writeln("${returnTypeString} ${method.name}${functionTemplates}(${argListDeclarations}) {");
        buffer.writeln("return _internal.${method.name}${functionTemplates}(${argList});");
        buffer.writeln("}");
      }

      for (final field in element.fields) {
        if (field.name.startsWith("_")) {continue;}

        forwardField(field);
      }

      for (final method in element.methods) {
        forwardMethod(method);
      }

      buffer.write("${className}(this._internal)");
      if(copyOnInitialise.isNotEmpty) {
        buffer.writeln(" {");
        for(final fromVarName in copyOnInitialise.keys) {
          final toVarName = copyOnInitialise[fromVarName];
          final toVarType = copyOnInitialiseType[fromVarName];

          buffer.writeln("${toVarName} = ${toVarType}(_internal.${fromVarName});");
        }
        buffer.writeln("}");
      }
      else {
        buffer.writeln(";");
      }

      buffer.writeln("}");

      buffer.writeln("extension ${classNamePublic}Extension${templateDeclarations} on ${parentClassName}${templates} {");
      buffer.writeln("${className}${templates} asController() => ${className}${templates}(this);");
      buffer.writeln("${className}${templates} ctx() => ${className}${templates}(this);");
      buffer.writeln("}");

      return buffer.toString();
    }
    else {
      return "/* UNABLE TO GENERATE ANNOTATION FOR NON-CLASS */";
    }
  }
}
