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
import 'package:registry/registry.dart';
import '../components/detail_rows.dart';
import '../components/dialog_builder.dart';
import '../components/empty.dart';
import '../components/version_edit.dart';
import '../models/selection.dart';
import '../models/version.dart';
import '../service/registry.dart';

// VersionDetailCard is a card that displays details about a version.
class VersionDetailCard extends StatefulWidget {
  final bool? selflink;
  final bool? editable;
  VersionDetailCard({this.selflink, this.editable});
  _VersionDetailCardState createState() => _VersionDetailCardState();
}

class _VersionDetailCardState extends State<VersionDetailCard> {
  ApiManager? apiManager;
  VersionManager? versionManager;
  Selection? selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setApiName(SelectionProvider.of(context)!.apiName.value);
      setVersionName(SelectionProvider.of(context)!.versionName.value);
    });
  }

  void setApiName(String name) {
    if (apiManager?.name == name) {
      return;
    }
    // forget the old manager
    apiManager?.removeListener(managerListener);
    // get a manager for the new name
    apiManager = RegistryProvider.of(context)!.getApiManager(name);
    apiManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  void setVersionName(String name) {
    if (versionManager?.name == name) {
      return;
    }
    // forget the old manager
    versionManager?.removeListener(managerListener);
    // get a manager for the new name
    versionManager = RegistryProvider.of(context)!.getVersionManager(name);
    versionManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.versionName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  @override
  void dispose() {
    apiManager?.removeListener(managerListener);
    versionManager?.removeListener(managerListener);
    selection!.versionName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (versionManager?.value == null) {
      return emptyCard(context, "version");
    }

    Function? selflink = onlyIf(widget.selflink, () {
      ApiVersion version = (versionManager?.value)!;
      Navigator.pushNamed(
        context,
        version.routeNameForDetail(),
      );
    });
    Function? editable = onlyIf(widget.editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection!,
              child: AlertDialog(
                content: DialogBuilder(
                  child: EditVersionForm(),
                ),
              ),
            );
          });
    });

    Api? api = apiManager!.value;
    ApiVersion version = versionManager!.value!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: version.name.split("/").sublist(4).join("/"),
            show: selflink as void Function()?,
            edit: editable as void Function()?,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageSection(
                      children: [
                        SizedBox(height: 10),
                        SuperTitleRow(api?.displayName ?? ""),
                        TitleRow(version.name.split("/").last,
                            action: selflink),
                      ],
                    ),
                    if (version.description != "")
                      PageSection(
                        children: [
                          BodyRow(version.description),
                        ],
                      ),
                    PageSection(
                      children: [
                        TimestampRow(version.createTime, version.updateTime),
                      ],
                    ),
                    if (version.labels.length > 0)
                      PageSection(children: [
                        LabelsRow(version.labels),
                      ]),
                    if (version.annotations.length > 0)
                      PageSection(children: [
                        AnnotationsRow(version.annotations),
                      ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
