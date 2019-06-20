import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_tooltip/module.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/user.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'payment_service.dart';

@Component(
  selector: 'payminator',
  styleUrls: [
    'payminator_component.scss.css',
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
  ],
  templateUrl: 'payminator_component.html',
  directives: [
    formDirectives,
    materialInputDirectives,
    materialNumberInputDirectives,
    MaterialTooltipDirective,
    MaterialIconTooltipComponent,
    MaterialButtonComponent,
    MaterialDropdownSelectComponent,
    NgIf,
  ],
  providers: [
    ClassProvider(PaymentService),
    popupBindings,
    materialTooltipBindings,
  ],
)
class PayminatorComponent extends AuthGuard implements OnActivate {
  final PaymentService paymentService;
  UserBloc userBloc;
  AuthBloc authBloc;

  User user;

  String username;
  int value;

  bool isNameValid = false;
  bool isSubmitDisabled = true;

  StreamSubscription focusListener;

  List<int> valueOptions = [5, 10, 15, 25, 50, -1];
  int selectedValue = 5;
  bool isCustomValue = false;

  PayminatorComponent(
    AuthProvider authProvider,
    UserProvider userProvider,
    Router router,
    this.paymentService,
  ) : super(authProvider, router) {
    authBloc = authProvider.authBloc;
    userBloc = userProvider.userBloc;
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    /// listen for user information and make value field accessible if all is okay
    userBloc.state.listen((UserState state) {
      if (state.isResult) {
        user = state.value;
        if (user.name != null && user.name.isNotEmpty && user.userId != null) {
          isNameValid = true;
        }
      }
    });

    /// listen on window focus to refresh credit after returning from paypal
    focusListener = window.onFocus.listen(
      (Event e) {
        userBloc.onRefresh();
      },
    );
  }

  void onDropdownValueChanged(int value) {
    if (value != -1) {
      isCustomValue = false;
      this.value = value;
    } else {
      isCustomValue = true;
    }

    isSubmitDisabled = false;
    selectedValue = value;
  }

  void onLogout() {
    authBloc.logout();
    window.localStorage.remove('token');
  }

  void onSubmitPayment() async {
    //print('value: $value\nselected value: $selectedValue ');
    final String url = await paymentService.getPaymentUrl(user.userId, value);
    window.open(url, 'test');
  }

  void onValueChanged(String value) {
    int numValue = int.tryParse(value);

    if (numValue != null && numValue > 0) {
      isSubmitDisabled = false;
      if (numValue < 1) {
        /// TODO: do stuff to show this error
      }
    } else {
      isSubmitDisabled = true;
    }
  }

  String renderValueOption(dynamic value) {
    if (((value is int) ? value : int.tryParse(value)) == -1) {
      return 'Benutzerdefiniert';
    } else {
      return (value as double).toStringAsFixed(2) + ' €';
    }
  }

  String selectedValueFormatted() {
    if (selectedValue == -1) {
      return 'Benutzerdefiniert';
    } else {
      return (selectedValue as double).toStringAsFixed(2) + ' €';
    }
  }
}
