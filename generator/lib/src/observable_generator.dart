import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:source_gen/source_gen.dart";
import "package:build/build.dart";
import "package:synaps/src/annotations.dart";

Type typeOf<T>() => T;

class ObservableGenerator extends GeneratorForAnnotation<Controller> {
  void _checkAnnotationInternal<T>(Element element,Map<Type,DartObject> out) {
    final annotations =
        TypeChecker.fromRuntime(T).annotationsOf(element);
    if (annotations.isNotEmpty) {
      out[typeOf<T>()]  = annotations.first;
    }
  }

  Map<Type,DartObject> getFieldAnnotations(Element element,[Map<Type,DartObject> out]) {
    out ??= {};

    _checkAnnotationInternal<Observable>(element, out);
    if(element is FieldElement) {
      if(element.getter != null) {
        getFieldAnnotations(element.getter, out);
      }
      
      if(element.setter != null) {
        getFieldAnnotations(element.setter, out);
      }
    }

    return out;
  }

  bool _isControllerClass(DartType type) {
    final element = type.element;
    final annotations =
        TypeChecker.fromRuntime(Controller).annotationsOf(element);
    
    return annotations.isNotEmpty;
  }

  String _getControllerClassTypeString(InterfaceType interfaceType,[bool deep = false]) {
    final element = interfaceType.element;
    final parentClassName = element.displayName;
    final classNameClean = parentClassName + "Controller";
    final classNameIdentifier = r"$" + classNameClean;

    var typeString = classNameIdentifier;
    
    if(interfaceType.typeArguments.isNotEmpty) {
      final templateList = <String>[];
      for(final fieldTypeArgument in interfaceType.typeArguments) {
        if(deep && _isControllerClass(fieldTypeArgument)) {
          templateList.add(_getControllerClassTypeString(fieldTypeArgument));
        }
        else {
          templateList.add(fieldTypeArgument.getDisplayString(withNullability: false));
        }
      }
      typeString += "<";
      typeString += templateList.join(",");
      typeString += ">";
    }

    return typeString;
  }

  @override
  String generateForAnnotatedElement(Element element, 
      ConstantReader classAnnotation, BuildStep buildStep) {
    
    if (element is ClassElement && !element.isEnum) {
      final buffer = StringBuffer();

      final parentClassName = element.displayName;
      final classNameClean = parentClassName + "Controller";
      final classNameIdentifier = r"$" + classNameClean;
      final templateDeclarations = element.typeParameters.isNotEmpty ?
        "<" + element.typeParameters.map((t) => t.getDisplayString(withNullability: false)).join(",") + ">"
          : "";
      final templates = element.typeParameters.isNotEmpty ?
        "<" + element.typeParameters.map((t) => t.name).join(",") + ">"
          : "";

      buffer.write("class ${classNameIdentifier}${templateDeclarations} ");
      buffer.write("extends ${parentClassName}${templates} ");
      final hasWEC = element.mixins
          .any((mxn) => mxn.element.name == "WeakEqualityController");
      final filteredMixins = element.mixins
          .where((mxn) => mxn.element.name != "WeakEqualityController");
      if(filteredMixins.isNotEmpty) {
        final mixinList = filteredMixins.map((mxn) => mxn.getDisplayString(withNullability: false)).join(",");

        buffer.write("with SynapsControllerInterface<${parentClassName}${templates}>,${mixinList} ");
      }
      else {
        buffer.write("with SynapsControllerInterface<${parentClassName}${templates}> ");
      }
      buffer.writeln("{");
      buffer.writeln("@override");
      buffer.writeln("final ${parentClassName}${templates} boxedValue;");

      final activateCtxOnInitialise = <String,String>{};

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

          if(field.type.isDartCoreList || field.type.isDartCoreSet || field.type.isDartCoreMap) {
            final proxyName = "_proxy_${field.name}";
            final typeString = field.type.getDisplayString(withNullability: false);
            var boxedTypeString = typeString;
            if(field.type.isDartCoreList) {
              boxedTypeString = "List";
            }
            else if(field.type.isDartCoreSet) {
              boxedTypeString = "Set";
            }
            else if(field.type.isDartCoreMap) {
              boxedTypeString = "Map";
            }
            if(field.type is InterfaceType) {
              final fieldTypeArguments = (field.type as InterfaceType).typeArguments;

              if(fieldTypeArguments.isNotEmpty) {
                final templateList = <String>[];
                for(final fieldTypeArgument in fieldTypeArguments) {
                  if(_isControllerClass(fieldTypeArgument)) {
                    templateList.add(_getControllerClassTypeString(fieldTypeArgument));
                  }
                  else {
                    templateList.add(fieldTypeArgument.getDisplayString(withNullability: false));
                  }
                }
                boxedTypeString += "<";
                boxedTypeString += templateList.join(",");
                boxedTypeString += ">";
              }
            }

            final proxyTypeString = "Synaps" + typeString;
            final boxedProxyTypeString = "Synaps" + boxedTypeString;

            activateCtxOnInitialise[field.name] = proxyName;

            if(field.getter != null) {
              buffer.writeln("${proxyTypeString} ${proxyName};");
              buffer.writeln("@override");
              buffer.writeln("${proxyTypeString} get ${field.name} {");
              buffer.writeln("synapsMarkVariableRead(#${field.name});");
              buffer.writeln("return ${proxyName};");
              buffer.writeln("}");
            }

            if(!field.isFinal) {
              buffer.writeln("@override");
              buffer.writeln("set ${field.name}(${typeString} value) {");
              buffer.writeln("${proxyName} = value.ctx();");
              buffer.writeln("boxedValue.${field.name} = ${proxyName};");
              buffer.writeln("synapsMarkVariableDirty(#${field.name},value);");
              buffer.writeln("}");
            }
          }
          else if(_isControllerClass(field.type)) {
            final proxyName = "_proxy_${field.name}";
            final typeString = field.type.getDisplayString(withNullability: false);
            final boxedTypeString = _getControllerClassTypeString(field.type);

            activateCtxOnInitialise[field.name] = proxyName;

            if(field.getter != null) {
              buffer.writeln("${boxedTypeString} ${proxyName};");
              buffer.writeln("@override");
              buffer.writeln("${boxedTypeString} get ${field.name} {");
              buffer.writeln("synapsMarkVariableRead(#${field.name});");
              buffer.writeln("return ${proxyName};");
              buffer.writeln("}");
            }

            if(!field.isFinal) {
              buffer.writeln("@override");
              buffer.writeln("set ${field.name}(${typeString} value) {");
              buffer.writeln("${proxyName} = value.ctx();");
              buffer.writeln("boxedValue.${field.name} = ${proxyName}.boxedValue;");
              buffer.writeln("synapsMarkVariableDirty(#${field.name},value);");
              buffer.writeln("}");
            }
          }
          else {
            final typeString = field.type.getDisplayString(withNullability: false);

            if(field.getter != null) {
              buffer.writeln("@override");
              buffer.writeln("${typeString} get ${field.name} {");
              buffer.writeln("synapsMarkVariableRead(#${field.name});");
              buffer.writeln("return boxedValue.${field.name};");
              buffer.writeln("}");
            }

            if(!field.isFinal) {
              buffer.writeln("@override");
              buffer.writeln("set ${field.name}(${typeString} value) {");
              buffer.writeln("boxedValue.${field.name} = value;");
              buffer.writeln("synapsMarkVariableDirty(#${field.name},value);");
              buffer.writeln("}");
            }
          }
        }
        else {
          final typeString = field.type.getDisplayString(withNullability: false);

          if(field.getter != null) {
            buffer.writeln("@override");
            buffer.writeln("${typeString} get ${field.name} {");
            buffer.writeln("return boxedValue.${field.name};");
            buffer.writeln("}");
          }

          if(!field.isFinal) {
            buffer.writeln("@override");
            buffer.writeln("set ${field.name}(${typeString} value) {");
            buffer.writeln("boxedValue.${field.name} = value;");
            buffer.writeln("}");
          }
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
        buffer.writeln("return super.${method.name}${functionTemplates}(${argList});");
        buffer.writeln("}");
      }

      for (final field in element.fields) {
        if (field.name.startsWith("_")) {continue;}
        if (field.isStatic) {continue;}

        forwardField(field);
      }

      for (final method in element.methods) {
        if (method.isStatic) {continue;}
        forwardMethod(method);
      }

      buffer.write("${classNameIdentifier}(this.boxedValue)");
      if(activateCtxOnInitialise.isNotEmpty || hasWEC) {
        buffer.writeln(" {");
        for(final fromVarName in activateCtxOnInitialise.keys) {
          final toVarName = activateCtxOnInitialise[fromVarName];

          buffer.writeln("${toVarName} = boxedValue.${fromVarName} != null ? boxedValue.${fromVarName}.ctx() : null;");
        }
        buffer.writeln("}");
      }
      else {
        buffer.writeln(";");
      }

      if(hasWEC) {
        buffer.writeln("@override");
        buffer.writeln("bool operator ==(Object other) {");
        buffer.writeln("if (identical(other, this)) {");
        buffer.writeln("return true;");
        buffer.writeln("}");
        
        buffer.writeln("if (identical(other, boxedValue)) {");
        buffer.writeln("return true;");
        buffer.writeln("}");
        
        buffer.writeln("if ((other is SynapsControllerInterface) && identical(other.boxedValue, boxedValue)) {");
        buffer.writeln("return true;");
        buffer.writeln("}");

        buffer.writeln("return false;");
        buffer.writeln("}");

        buffer.writeln("@override");
        buffer.writeln("int get hashCode => boxedValue.hashCode;");
      }

      buffer.writeln("}");

      buffer.writeln("extension ${classNameClean}Extension${templateDeclarations} on ${parentClassName}${templates} {");
      buffer.writeln("${classNameIdentifier}${templates} asController() {");
      buffer.writeln("if(this is ${classNameIdentifier}) return this;");
      buffer.writeln("return ${classNameIdentifier}${templates}(this);");
      buffer.writeln("}");
      buffer.writeln("${classNameIdentifier}${templates} ctx() => asController();");
      buffer.writeln("${parentClassName}${templates} get boxedValue => this;");
      buffer.writeln("}");

      return buffer.toString();
    }
    else {
      return "/* UNABLE TO GENERATE ANNOTATION FOR NON-CLASS */";
    }
  }
}
