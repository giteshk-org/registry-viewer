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
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:registry/registry.dart';
import 'custom_search_box.dart';
import 'filter.dart';
import '../models/project.dart';
import '../models/selection.dart';
import '../models/string.dart';
import '../service/service.dart';
import '../helpers/errors.dart';

typedef ProjectSelectionHandler = Function(
    BuildContext context, Project project);

// ProjectListCard is a card that displays a list of projects.
class ProjectListCard extends StatefulWidget {
  @override
  _ProjectListCardState createState() => _ProjectListCardState();
}

class _ProjectListCardState extends State<ProjectListCard> {
  ProjectService? projectService;
  PagewiseLoadController<Project>? pageLoadController;

  _ProjectListCardState() {
    projectService = ProjectService();
    pageLoadController = PagewiseLoadController<Project>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => projectService!.getProjectsPage(pageIndex!));
  }

  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, ProjectSearchBox(),
                refresh: () => pageLoadController!.reset()),
            Expanded(
              child: ProjectListView(
                null,
                projectService,
                pageLoadController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ProjectListView is a scrollable ListView of projects.
class ProjectListView extends StatefulWidget {
  final ProjectSelectionHandler? selectionHandler;
  final ProjectService? projectService;
  final PagewiseLoadController<Project>? pageLoadController;

  ProjectListView(
    this.selectionHandler,
    this.projectService,
    this.pageLoadController,
  );

  @override
  _ProjectListViewState createState() => _ProjectListViewState();
}

class _ProjectListViewState extends State<ProjectListView> {
  int selectedIndex = -1;
  final ScrollController scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    ObservableStringProvider.of(context)!.addListener(() => setState(() {
          ObservableString? filter = ObservableStringProvider.of(context);
          if (filter != null) {
            widget.projectService!.filter = filter.value;
            widget.pageLoadController!.reset();
            selectedIndex = -1;
          }
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    widget.projectService!.onError = () => setState(() {});

    if (widget.pageLoadController?.error != null) {
      reportError(context, widget.pageLoadController?.error);
      return Text("${widget.pageLoadController!.error}");
    }
    return Scrollbar(
      controller: scrollController,
      child: PagewiseListView<Project>(
        itemBuilder: this._itemBuilder,
        pageLoadController: widget.pageLoadController,
        controller: scrollController,
      ),
    );
  }

  Widget _itemBuilder(context, Project project, index) {
    if (index == 0) {
      Future.delayed(const Duration(), () {
        Selection? selection = SelectionProvider.of(context);
        if ((selection != null) && (selection.projectName.value == "")) {
          selection.updateProjectName(project.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
      title: Text(project.nameForDisplay()),
      subtitle: Text(project.description),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        Selection? selection = SelectionProvider.of(context);
        selection?.updateProjectName(project.name);
        widget.selectionHandler?.call(context, project);
      },
      trailing: IconButton(
        color: Colors.black,
        icon: Icon(Icons.open_in_new),
        tooltip: "open",
        onPressed: () {
          Navigator.pushNamed(
            context,
            project.routeNameForDetail(),
          );
        },
      ),
    );
  }
}

// ProjectSearchBox provides a search box for projects.
class ProjectSearchBox extends CustomSearchBox {
  ProjectSearchBox()
      : super(
          "Filter Projects",
          "project_id.contains('TEXT')",
        );
}
