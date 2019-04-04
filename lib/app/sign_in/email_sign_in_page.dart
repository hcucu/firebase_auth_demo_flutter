import 'package:firebase_auth_demo_flutter/app/sign_in/email_sign_in_bloc.dart';
import 'package:firebase_auth_demo_flutter/app/sign_in/email_sign_in_model.dart';
import 'package:firebase_auth_demo_flutter/common_widgets/form_submit_button.dart';
import 'package:firebase_auth_demo_flutter/common_widgets/platform_exception_alert_dialog.dart';
import 'package:firebase_auth_demo_flutter/constants/strings.dart';
import 'package:firebase_auth_demo_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// This class relies on a EmailSignInBloc + StreamBuilder to manage its state.
/// However, it still needs to be a StatefulWidget due to an issue when
/// TextEditingController and StreamBuilder are used together.
class EmailSignInPage extends StatefulWidget {
  const EmailSignInPage._({Key key, this.bloc}) : super(key: key);
  final EmailSignInBloc bloc;

  /// Creates a Provider with a EmailSignInBloc and a EmailSignInPage
  static Widget create(BuildContext context) {
    final AuthService auth = Provider.of<AuthService>(context);
    return StatefulProvider<EmailSignInBloc>(
      valueBuilder: (BuildContext context) => EmailSignInBloc(auth: auth),
      onDispose: (BuildContext context, EmailSignInBloc bloc) => bloc.dispose(),
      child: Consumer<EmailSignInBloc>(
        builder: (BuildContext context, EmailSignInBloc bloc) => EmailSignInPage._(bloc: bloc),
      ),
    );
  }

  @override
  _EmailSignInPageState createState() => _EmailSignInPageState();
}

class _EmailSignInPageState extends State<EmailSignInPage> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _showSignInError(EmailSignInModel model, PlatformException exception) {
    PlatformExceptionAlertDialog(
      title: model.formType == EmailSignInFormType.signIn ? Strings.signInFailed : Strings.registrationFailed,
      exception: exception,
    ).show(context);
  }

  void _unfocus() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
  }

  Future<void> _submit(EmailSignInModel model) async {
    _unfocus();
    try {
      await widget.bloc.submit();
    } on PlatformException catch (e) {
      _showSignInError(model, e);
    }
  }

  void _emailEditingComplete(EmailSignInModel model) {
    final FocusNode newFocus = model.canSubmitEmail ? _passwordFocusNode : _emailFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  void _toggleFormType() {
    widget.bloc.toggleFormType();
    _emailController.clear();
    _passwordController.clear();
  }

  Widget _buildEmailField(EmailSignInModel model) {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      decoration: InputDecoration(
        labelText: Strings.emailLabel,
        hintText: Strings.emailHint,
        errorText: model.emailErrorText,
        enabled: !model.isLoading,
      ),
      autocorrect: false,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
      onChanged: widget.bloc.updateEmail,
      onEditingComplete: () => _emailEditingComplete(model),
      inputFormatters: <TextInputFormatter>[
        model.emailInputFormatter,
      ],
    );
  }

  Widget _buildPasswordField(EmailSignInModel model) {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      decoration: InputDecoration(
        labelText: Strings.passwordLabel,
        errorText: model.passwordErrorText,
        enabled: !model.isLoading,
      ),
      obscureText: true,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onChanged: widget.bloc.updatePassword,
      onEditingComplete: () => _submit(model),
    );
  }

  Widget _buildContent(EmailSignInModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: 8.0),
        _buildEmailField(model),
        SizedBox(height: 8.0),
        _buildPasswordField(model),
        SizedBox(height: 8.0),
        FormSubmitButton(
          text: model.primaryButtonText,
          loading: model.isLoading,
          onPressed: () => _submit(model),
        ),
        SizedBox(height: 8.0),
        FlatButton(
          child: Text(model.secondaryButtonText),
          onPressed: model.isLoading ? null : _toggleFormType,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EmailSignInModel>(
      stream: widget.bloc.modelStream,
      initialData: EmailSignInModel(),
      builder: (BuildContext context, AsyncSnapshot<EmailSignInModel> snapshot) {
        final EmailSignInModel model = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            elevation: 2.0,
            title: Text(model.formType == EmailSignInFormType.signIn ? Strings.signIn : Strings.register),
          ),
          backgroundColor: Colors.grey[200],
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: _buildContent(model),
                  //child: _buildEmailSignInForm(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}