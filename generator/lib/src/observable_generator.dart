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
    final classNameClean = parentClassName;
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
      final classNameClean = parentClassName;
      final classNameIdentifier = r"$" + classNameClean;
      final templateDeclarations = element.typeParameters.isNotEmpty ?
        "<" + element.typeParameters.map((t) => t.getDisplayString(withNullability: false)).join(",") + ">"
          : "";
      final templates = element.typeParameters.isNotEmpty ?
        "<" + element.typeParameters.map((t) => t.name).join(",") + ">"
          : "";

      buffer.write("class ${classNameIdentifier}${templateDeclarations} ");
      buffer.write("extends ${parentClassName}${templates} ");
      buffer.write("with SynapsControllerInterface<${parentClassName}${templates}> ");
      final hasWEC = element.mixins
          .any((mxn) => mxn.element.name == "WeakEqualityController");
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
              buffer.writeln("${proxyName} = value != null ? value.ctx() : null;");
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
              buffer.writeln("${proxyName} = value != null ? value.ctx() : null;");
              buffer.writeln("boxedValue.${field.name} = value != null ? ${proxyName}.boxedValue : null;");
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

      String getTemplatesString(List<TypeParameterElement> typeParameters) {
        return typeParameters.isNotEmpty ?
          "<" + typeParameters.map((t) => t.name).join(",") + ">"
            : "";
      }

      String getArgListDeclarations(List<ParameterElement> parameters) {
        var argListDeclarations = "";
        
        final numPositionalArgs = parameters
          .fold(0,(val,param) => val + (param.isRequiredPositional ? 1 : 0));
        final hasOptionalPositional = parameters
          .any((param) => param.isOptionalPositional);
        final hasNamed = parameters
          .any((param) => param.isNamed);
        
        // Generate all argument declarations
        argListDeclarations += parameters.where((param) => param.isRequiredPositional).map((param) {
          return param.type.getDisplayString(withNullability: false)
            + " " + param.name;
        }).join(",");

        if(hasOptionalPositional) {
          if(numPositionalArgs > 0) {
            argListDeclarations += ",";
          }

          argListDeclarations += "[";
          
          argListDeclarations += parameters.where((param) => param.isOptionalPositional).map((param) {
            return param.type.getDisplayString(withNullability: false)
              + " " + param.name + (param.hasDefaultValue ? (" = " + param.defaultValueCode) : "");
          }).join(",");

          argListDeclarations += "]";
        }
        else if(hasNamed) {
          if(numPositionalArgs > 0) {
            argListDeclarations += ",";
          }

          argListDeclarations += "{";
          
          argListDeclarations += parameters.where((param) => param.isNamed).map((param) {
            var cParam = param.type.getDisplayString(withNullability: false)
              + " " + param.name;

            if(param.hasRequired) {
              cParam = "@required " + cParam;
            }

            return cParam;
          }).join(",");

          argListDeclarations += "}";
        }

        return argListDeclarations;
      }
        
      String getArgListExpressions(List<ParameterElement> parameters) {
        var argListExpressions = "";
        
        final numPositionalArgs = parameters
          .fold(0,(val,param) => val + (param.isRequiredPositional ? 1 : 0));
        final hasOptionalPositional = parameters
          .any((param) => param.isOptionalPositional);
        final hasNamed = parameters
          .any((param) => param.isNamed);

        // Generate all argument expressions
        argListExpressions += parameters.where((param) => param.isRequiredPositional).map((param) {
          return param.name;
        }).join(",");

        if(hasOptionalPositional) {
          if(numPositionalArgs > 0) {
            argListExpressions += ",";
          }

          argListExpressions += parameters.where((param) => param.isOptionalPositional).map((param) {
            return param.name;
          }).join(",");
        }
        else if(hasNamed) {
          if(numPositionalArgs > 0) {
            argListExpressions += ",";
          }

          argListExpressions += parameters.where((param) => param.isNamed).map((param) {
            return param.name + ": " + param.name;
          }).join(",");
        }

        return argListExpressions;
      }

      void forwardMethod(MethodElement method) {
        // final library = method.session.getParsedLibraryByElement(method.library);
        // final astNode = library.getElementDeclaration(method);

        // buffer.writeln("@override");
        // buffer.writeln(astNode.node.toSource());
        
        final returnTypeString = method.returnType.getDisplayString(withNullability: false);

        final functionTemplates = getTemplatesString(method.typeParameters);
        final argListDeclarations = getArgListDeclarations(method.parameters);
        final argListExpressions = getArgListExpressions(method.parameters);

        buffer.writeln("@override");
        buffer.writeln("${returnTypeString} ${method.name}${functionTemplates}(${argListDeclarations}) {");
        buffer.write("return ");
        if(method.isAbstract) {
          buffer.write("boxedValue");
        }
        else {
          buffer.write("super");
        }
        buffer.writeln(".${method.name}${functionTemplates}(${argListExpressions});");
        buffer.writeln("}");
      }

      final seenFields = <String>{};
      void recurseSubclass(ClassElement recElement,[Set<Element> seen]) {
        if(recElement.isDartCoreObject) {return;}

        seen ??= {};

        if(seen.contains(recElement)) return;
        seen.add(recElement);
        
        for (final field in recElement.fields) {
          if (field.name.startsWith("_")) {continue;}
          if (field.isStatic) {continue;}
          if (seenFields.contains(field.name)) {continue;}
          seenFields.add(field.name);

          forwardField(field);
        }

        for (final method in recElement.methods) {
          if (method.name.startsWith("_")) {continue;}
          if (method.isStatic) {continue;}
          // if (method.isAbstract) {continue;}
          if(hasWEC && method.isOperator && method.name == "==") {continue;}
          if (seenFields.contains(method.name)) {continue;}
          seenFields.add(method.name);

          forwardMethod(method);
        }

        if(recElement.supertype != null) {
          if(recElement.supertype.element is ClassElement) {
            recurseSubclass(recElement.supertype.element,seen);
          }
        }

        for(final mxn in recElement.mixins) {
          if(mxn.element is ClassElement) {
            recurseSubclass(mxn.element,seen);
          }
        }

        for(final interface in recElement.interfaces) {
          if(interface.element is ClassElement) {
            recurseSubclass(interface.element,seen);
          }
        }
      }

      recurseSubclass(element);

      if(element.unnamedConstructor != null) {
        if(element.unnamedConstructor.parameters.isNotEmpty) {
          throw AssertionError("""
          [synaps_generator] A class annotated with @Controller() MUST have a
          zero-argument unnamed constructor. If the constructor has any arguments
          at all, it is difficult for synaps to wrap that class, as Synaps has to
          initialise that class first.

          Consider using a named constructor instead.
          """);
        }
      }

      for(final namedConstructor in element.constructors) {
        if(namedConstructor.name.isNotEmpty) {
          final functionTemplates = getTemplatesString(namedConstructor.typeParameters);
          final argListDeclarations = getArgListDeclarations(namedConstructor.parameters);
          final argListExpressions = getArgListExpressions(namedConstructor.parameters);

          buffer.write("${classNameIdentifier}.${namedConstructor.name}${functionTemplates}(${argListDeclarations})");
          buffer.write(" : ");
          buffer.write("super.${namedConstructor.name}${functionTemplates}(${argListExpressions})");
          buffer.writeln(";");
        }
      }

      buffer.write("${classNameIdentifier}(this.boxedValue)");
      buffer.writeln(" : super()");
      if(activateCtxOnInitialise.isNotEmpty) {
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
