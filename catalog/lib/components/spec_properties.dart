// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/selection.dart';

String projectNameForSpecName(String specName) {
  print("spec name $specName");
  final projectName = specName.split("/").sublist(0, 2).join("/");
  print("project name $projectName");
  return projectName;
}

// SpecPropertiesCard

class SpecPropertiesCard extends StatefulWidget {
  @override
  _SpecPropertiesCardState createState() => _SpecPropertiesCardState();
}

class _SpecPropertiesCardState extends State<SpecPropertiesCard> {
  String specName;
  List<Property> properties;
  _SpecPropertiesCardState();

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).specName.addListener(() => setState(() {
          specName = SelectionProvider.of(context).specName.value;
          if (specName == null) {
            specName = "";
          }
          this.properties = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (specName == null) {
      return Card();
    }
    if (properties == null) {
      // we need to fetch the properties from the API
      final propertiesFuture = PropertiesService.listProperties(
          projectNameForSpecName(specName),
          subject: specName);
      propertiesFuture.then((properties) {
        setState(() {
          this.properties = properties.properties;
        });
      });
      return Card();
    }
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Properties",
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          Table(
              columnWidths: {
                0: IntrinsicColumnWidth(),
              },
              children: properties.map(
                (property) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          property.relation,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  );
                },
              ).toList()),
        ],
      ),
    );
  }
}
