import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_editor/html_editor.dart';
import 'package:mobile_app/app_theme.dart';
import 'package:mobile_app/locator.dart';
import 'package:mobile_app/models/projects.dart';
import 'package:mobile_app/services/dialog_service.dart';
import 'package:mobile_app/ui/components/cv_primary_button.dart';
import 'package:mobile_app/ui/components/cv_text_field.dart';
import 'package:mobile_app/ui/views/base_view.dart';
import 'package:mobile_app/utils/snackbar_utils.dart';
import 'package:mobile_app/utils/validators.dart';
import 'package:mobile_app/viewmodels/projects/edit_project_viewmodel.dart';

class EditProjectView extends StatefulWidget {
  static const String id = 'edit_project_view';
  final Project project;

  const EditProjectView({Key key, this.project}) : super(key: key);

  @override
  _EditProjectViewState createState() => _EditProjectViewState();
}

class _EditProjectViewState extends State<EditProjectView> {
  final DialogService _dialogService = locator<DialogService>();
  EditProjectViewModel _model;
  final _formKey = GlobalKey<FormState>();
  String _name, _projectAccessType;
  List<String> _tags;
  final GlobalKey<HtmlEditorState> _descriptionEditor = GlobalKey();

  @override
  void initState() {
    super.initState();
    _name = widget.project.attributes.name;
    _tags = widget.project.attributes.tags.map((tag) => tag.name).toList();
    _projectAccessType = widget.project.attributes.projectAccessType;
  }

  Widget _buildNameInput() {
    return CVTextField(
      label: 'Name',
      initialValue: _name,
      validator: (value) => value.isEmpty ? "Name can't be empty" : null,
      onSaved: (value) => _name = value.trim(),
    );
  }

  Widget _buildTagsInput() {
    return CVTextField(
      label: 'Tags List',
      initialValue: _tags.join(' , '),
      onSaved: (value) =>
          _tags = value.split(',').map((tag) => tag.trim()).toList(),
    );
  }

  Widget _buildProjectAccessTypeInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: AppTheme.textFieldDecoration.copyWith(
          labelText: 'Project Access Type',
        ),
        value: _projectAccessType,
        onChanged: (String value) {
          setState(() {
            _projectAccessType = value;
          });
        },
        validator: (category) =>
            category == null ? 'Choose a Project Access Type' : null,
        items: ['Public', 'Private', 'Limited Access']
            ?.map<DropdownMenuItem<String>>((var type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        })?.toList(),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: HtmlEditor(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColorDark,
          ),
        ),
        value: widget.project.attributes.description ?? '',
        key: _descriptionEditor,
        height: 300,
      ),
    );
  }

  Future<void> _validateAndSubmit() async {
    if (Validators.validateAndSaveForm(_formKey)) {
      FocusScope.of(context).requestFocus(FocusNode());

      _dialogService.showCustomProgressDialog(title: 'Updating..');

      await _model.updateProject(
        widget.project.id,
        name: _name,
        projectAccessType: _projectAccessType,
        description: await _descriptionEditor.currentState.getText(),
        tagsList: _tags,
      );

      _dialogService.popDialog();

      if (_model.isSuccess(_model.UPDATE_PROJECT)) {
        await Future.delayed(Duration(seconds: 1));
        await Get.back(result: _model.updatedProject);
        SnackBarUtils.showDark('Project Updated');
      } else if (_model.isError(_model.UPDATE_PROJECT)) {
        SnackBarUtils.showDark(_model.errorMessageFor(_model.UPDATE_PROJECT));
      }
    }
  }

  Widget _buildUpdateProjectButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CVPrimaryButton(
        title: 'Update Project',
        onPressed: _validateAndSubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<EditProjectViewModel>(
      onModelReady: (model) => _model = model,
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(title: Text('Edit ${widget.project.attributes.name}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                _buildNameInput(),
                _buildTagsInput(),
                _buildProjectAccessTypeInput(),
                _buildDescriptionInput(),
                SizedBox(height: 16),
                _buildUpdateProjectButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}