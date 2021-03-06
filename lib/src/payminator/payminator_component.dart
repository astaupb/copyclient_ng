import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_tooltip/module.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:intl/intl.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/user_provider.dart';
import 'payment_service.dart';

@Component(
  selector: 'payminator',
  styleUrls: [
    'payminator_component.scss.css',
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
    'package:copyclient_ng/styles/listpage_navigation.css',
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
    MaterialFabComponent,
    MaterialIconComponent,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialInkTooltipComponent,
    MaterialTooltipTargetDirective,
    NgIf,
    NgFor,
  ],
  providers: [
    ClassProvider(PaymentService),
    popupBindings,
    materialTooltipBindings,
    materialProviders,
  ],
)
class PayminatorComponent extends AuthGuard implements OnActivate, OnDeactivate {
  final PaymentService paymentService;
  UserBloc userBloc;
  AuthBloc authBloc;
  JournalBloc journalBloc;

  User user;

  String username;
  int value;

  bool isNameValid = false;
  bool isSubmitDisabled = true;

  StreamSubscription userListener;
  StreamSubscription journalListener;
  StreamSubscription focusListener;

  List<int> valueOptions = [5, 10, 15, 25, 50, -1];
  int selectedValue = 5;
  bool isCustomValue = false;

  List<Transaction> transactions;

  bool refreshing = false;

  PayminatorComponent(
    AuthProvider authProvider,
    UserProvider userProvider,
    JournalProvider journalProvider,
    Router router,
    this.paymentService,
  ) : super(authProvider, router) {
    authBloc = authProvider.authBloc;
    userBloc = userProvider.userBloc;
    journalBloc = journalProvider.journalBloc;
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    /// listen for user information and make value field accessible if all is okay
    userListener = userBloc.listen((UserState state) {
      if (state.isResult) {
        user = state.value;
        if (user.name != null && user.name.isNotEmpty && user.userId != null) {
          isNameValid = true;
        }
        refreshing = false;
      }
      if (state.isBusy) {
        refreshing = true;
      } else {
        refreshing = false;
      }
    });

    /// listen for new transactions from [JournalBloc] also
    journalListener = journalBloc.listen((JournalState state) {
      if (state.isResult) {
        transactions = state.value.transactions;
      }
    });

    /// listen on window focus to refresh credit after returning from paypal
    focusListener = window.onFocus.listen(
      (Event e) {
        userBloc.onRefresh();
      },
    );

    journalBloc.onRefresh();
    userBloc.onRefresh();
  }

  @override
  void onDeactivate(RouterState current, RouterState next) {
    focusListener.cancel();
    userListener.cancel();
    journalListener.cancel();
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
    authBloc.onLogout();
    window.localStorage.remove('token');
  }

  void onRefreshTransactions() {
    journalBloc.onRefresh();
  }

  void onSubmitPayment() async {
    //print('value: $value\nselected value: $selectedValue ');
    final String url = await paymentService.getPaymentUrl(user.userId, value);
    window.open(url, _paypalWindowTitle(user.name));
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
      return _userDefinedMessage();
    } else {
      return (value as double).toStringAsFixed(2) + ' €';
    }
  }

  String selectedValueFormatted() {
    if (selectedValue == -1) {
      return _userDefinedMessage();
    } else {
      return (selectedValue as double).toStringAsFixed(2) + ' €';
    }
  }

  String _paypalWindowTitle(String name) => Intl.message(
        'PayPal Zahlung für $name',
        name: '_paypalWindowTitle',
        args: [name],
        desc: 'Title of the newly opened paypal window containing the users name',
      );

  String _userDefinedMessage() => Intl.message(
        'Benutzerdefiniert',
        name: '_userDefinedMessage',
        desc: 'Shows a value can be user defined as opposed to a predefined value',
      );
}
