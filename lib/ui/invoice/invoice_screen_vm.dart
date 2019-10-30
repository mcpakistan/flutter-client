import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/invoice/invoice_actions.dart';
import 'package:invoiceninja_flutter/redux/invoice/invoice_selectors.dart';
import 'package:redux/redux.dart';

import 'invoice_screen.dart';

class InvoiceScreenBuilder extends StatelessWidget {
  const InvoiceScreenBuilder({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, InvoiceScreenVM>(
      //rebuildOnChange: true,
      converter: InvoiceScreenVM.fromStore,
      builder: (context, vm) {
        return InvoiceScreen(
          viewModel: vm,
        );
      },
    );
  }
}

class InvoiceScreenVM {
  InvoiceScreenVM({
    @required this.isInMultiselect,
    @required this.invoiceList,
    @required this.userCompany,
    @required this.onEntityAction,
    @required this.invoiceMap,
  });

  final bool isInMultiselect;
  final UserCompanyEntity userCompany;
  final List<String> invoiceList;
  final Function(BuildContext, List<BaseEntity>, EntityAction) onEntityAction;
  final BuiltMap<String, InvoiceEntity> invoiceMap;

  static InvoiceScreenVM fromStore(Store<AppState> store) {
    final state = store.state;

    return InvoiceScreenVM(
      invoiceMap: state.invoiceState.map,
      invoiceList: memoizedFilteredInvoiceList(
          state.invoiceState.map,
          state.invoiceState.list,
          state.clientState.map,
          state.invoiceListState),
      userCompany: state.userCompany,
      isInMultiselect: state.invoiceListState.isInMultiselect(),
      onEntityAction: (BuildContext context, List<BaseEntity> invoices,
              EntityAction action) =>
          handleInvoiceAction(context, invoices, action),
    );
  }
}