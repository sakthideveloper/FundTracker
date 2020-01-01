import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fund_tracker/models/category.dart';
import 'package:fund_tracker/models/transaction.dart';
import 'package:fund_tracker/services/fireDB.dart';
import 'package:fund_tracker/shared/loader.dart';
import 'package:provider/provider.dart';

class TransactionForm extends StatefulWidget {
  final Transaction tx;

  TransactionForm(this.tx);

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();

  DateTime _date;
  bool _isExpense;
  String _payee;
  double _amount;
  String _category;

  String _noCategories = 'NA';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<FirebaseUser>(context);
    final isEditMode = widget.tx.tid != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Transaction' : 'Add Transaction'),
        actions: isEditMode
            ? <Widget>[
                FlatButton(
                  textColor: Colors.white,
                  child: Icon(Icons.delete),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await FireDBService(uid: _user.uid)
                        .deleteTransaction(widget.tx.tid);
                    Navigator.pop(context);
                  },
                )
              ]
            : null,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 50.0,
        ),
        child: StreamBuilder<List<Category>>(
          stream: FireDBService(uid: _user.uid).categories,
          builder: (context, snapshot) {
            if (snapshot.hasData && !_isLoading) {
              List<Category> categories = snapshot.data;
              List<Category> enabledCategories =
                  categories.where((category) => category.enabled).toList();
              return Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Expanded(
                          child: FlatButton(
                            padding: EdgeInsets.all(15.0),
                            color: (_isExpense ?? widget.tx.isExpense)
                                ? Colors.grey[100]
                                : Theme.of(context).primaryColor,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                  fontWeight:
                                      (_isExpense ?? widget.tx.isExpense)
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                  color: (_isExpense ?? widget.tx.isExpense)
                                      ? Colors.black
                                      : Colors.white),
                            ),
                            onPressed: () => setState(() => _isExpense = false),
                          ),
                        ),
                        Expanded(
                          child: FlatButton(
                            padding: EdgeInsets.all(15.0),
                            color: (_isExpense ?? widget.tx.isExpense)
                                ? Theme.of(context).primaryColor
                                : Colors.grey[100],
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                fontWeight: (_isExpense ?? widget.tx.isExpense)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: (_isExpense ?? widget.tx.isExpense)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            onPressed: () => setState(() => _isExpense = true),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20.0),
                    FlatButton(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                              '${(_date ?? widget.tx.date).year.toString()}.${(_date ?? widget.tx.date).month.toString()}.${(_date ?? widget.tx.date).day.toString()}'),
                          Icon(Icons.date_range),
                        ],
                      ),
                      onPressed: () async {
                        DateTime date = await showDatePicker(
                          context: context,
                          initialDate: new DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(Duration(days: 365)),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _date = date);
                        }
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: widget.tx.payee,
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Enter a payee or a note.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Payee',
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (val) {
                        setState(() => _payee = val);
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: widget.tx.amount != null
                          ? widget.tx.amount.toStringAsFixed(2)
                          : null,
                      autovalidate: _amount != null,
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Please enter an amount.';
                        }
                        if (val.indexOf('.') > 0 &&
                            val.split('.')[1].length > 2) {
                          return 'At most 2 decimal places allowed.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Amount',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() => _amount = double.parse(val));
                      },
                    ),
                    SizedBox(height: 20.0),
                    DropdownButtonFormField(
                      validator: (val) {
                        if (val == _noCategories) {
                          return 'Add categories in preferences.';
                        }
                        return null;
                      },
                      value: (_category ?? widget.tx.category) ??
                          (enabledCategories.length > 0
                              ?
                              // ListTile(
                              //     leading: CircleAvatar(
                              //       child: Icon(IconData(
                              //         enabledCategories[0].icon,
                              //         fontFamily: 'MaterialIcons',
                              //       )),
                              //       radius: 25.0,
                              //     ),
                              //     title: Text(categories[0].name),
                              //   )
                              enabledCategories.first.name
                              : _noCategories),
                      items: enabledCategories.length > 0
                          ? enabledCategories.map((category) {
                              return DropdownMenuItem(
                                value: category.name,
                                child: Text(category.name),
                                // child: ListTile(
                                //   leading: CircleAvatar(
                                //     child: Icon(IconData(
                                //       category.icon,
                                //       fontFamily: 'MaterialIcons',
                                //     )),
                                //     radius: 25.0,
                                //   ),
                                //   title: Text(category.name),
                                // ),
                              );
                            }).toList()
                          : [
                              DropdownMenuItem(
                                value: _noCategories,
                                child: Text(_noCategories),
                              )
                            ],
                      onChanged: (val) {
                        setState(() => _category = val);
                      },
                    ),
                    SizedBox(height: 20.0),
                    RaisedButton(
                      color: Theme.of(context).primaryColor,
                      child: Text(
                        isEditMode ? 'Save' : 'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          Transaction tx = Transaction(
                            tid: widget.tx.tid,
                            date: _date ?? widget.tx.date,
                            isExpense: _isExpense ?? widget.tx.isExpense,
                            payee: _payee ?? widget.tx.payee,
                            amount: _amount ?? widget.tx.amount,
                            category: _category ??
                                widget.tx.category ??
                                enabledCategories.first.name,
                          );
                          setState(() => _isLoading = true);
                          isEditMode
                              ? await FireDBService(uid: _user.uid)
                                  .updateTransaction(tx)
                              : await FireDBService(uid: _user.uid)
                                  .addTransaction(tx);
                          Navigator.pop(context);
                        }
                      },
                    )
                  ],
                ),
              );
            } else {
              return Loader();
            }
          },
        ),
      ),
    );
  }
}
