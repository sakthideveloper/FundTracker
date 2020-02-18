import 'package:fund_tracker/models/period.dart';
import 'package:fund_tracker/models/recurringTransaction.dart';
import 'package:fund_tracker/models/transaction.dart';
import 'package:fund_tracker/services/fireDB.dart';
import 'package:fund_tracker/services/localDB.dart';

class SyncService {
  final String uid;
  FireDBService _fireDBService;
  LocalDBService _localDBService;

  SyncService(this.uid) {
    this._fireDBService = FireDBService(this.uid);
    this._localDBService = LocalDBService();
  }

  void syncTransactions() async {
    List<Transaction> cloudTransactions =
        await _fireDBService.getTransactions().first;
    List<Transaction> localTransactions =
        await _localDBService.getTransactions(uid).first;
    List<Transaction> transactionsOnlyInCloud = cloudTransactions
        .where((cloud) =>
            localTransactions.where((local) => local.equalTo(cloud)).length ==
            0)
        .toList();
    List<Transaction> transactionsOnlyInLocal = localTransactions
        .where((local) =>
            cloudTransactions.where((cloud) => cloud.equalTo(local)).length ==
            0)
        .toList();
    _fireDBService.deleteTransactions(transactionsOnlyInCloud);
    _fireDBService.addTransactions(transactionsOnlyInLocal);
  }

  void syncCategories() async {
    await _fireDBService.deleteAllCategories();
    _localDBService
        .getCategories(uid)
        .first
        .then((categories) => _fireDBService.addCategories(categories));
  }

  void syncPeriods() async {
    List<Period> cloudPeriods = await _fireDBService.getPeriods().first;
    List<Period> localPeriods = await _localDBService.getPeriods(uid).first;
    List<Period> periodsOnlyInCloud = cloudPeriods
        .where((cloud) =>
            localPeriods.where((local) => local.equalTo(cloud)).length == 0)
        .toList();
    List<Period> periodsOnlyInLocal = localPeriods
        .where((local) =>
            cloudPeriods.where((cloud) => cloud.equalTo(local)).length == 0)
        .toList();
    _fireDBService.deletePeriods(periodsOnlyInCloud);
    _fireDBService.addPeriods(periodsOnlyInLocal);
  }

  void syncRecurringTransactions() async {
    List<RecurringTransaction> cloudRecurringTransactions =
        await _fireDBService.getRecurringTransactions().first;
    List<RecurringTransaction> localRecurringTransactions =
        await _localDBService.getRecurringTransactions(uid).first;
    List<RecurringTransaction> recurringTransactionsOnlyInCloud =
        cloudRecurringTransactions
            .where((cloud) =>
                localRecurringTransactions
                    .where((local) => local.equalTo(cloud))
                    .length ==
                0)
            .toList();
    List<RecurringTransaction> recurringTransactionsOnlyInLocal =
        localRecurringTransactions
            .where((local) =>
                cloudRecurringTransactions
                    .where((cloud) => cloud.equalTo(local))
                    .length ==
                0)
            .toList();
    _fireDBService
        .deleteRecurringTransactions(recurringTransactionsOnlyInCloud);
    _fireDBService.addRecurringTransactions(recurringTransactionsOnlyInLocal);
  }

  void syncPreferences() async {
    await _fireDBService.deletePreferences();
    _localDBService
        .getPreferences(uid)
        .first
        .then((preferences) => _fireDBService.addPreferences(preferences));
  }

  void syncToCloud() {
    syncTransactions();
    syncCategories();
    syncPeriods();
    syncPreferences();
  }

  Future syncToLocal() async {
    if (await _localDBService.findUser(uid) == null) {
      _fireDBService.findUser().then((user) => _localDBService.addUser(user));
    }
    _localDBService.getTransactions(uid).first.then((localTransactions) {
      if (localTransactions.length == 0) {
        _fireDBService.getTransactions().first.then((cloudTransactions) =>
            _localDBService.addTransactions(cloudTransactions));
      }
    });
    _localDBService.getCategories(uid).first.then((localCategories) {
      if (localCategories.length == 0) {
        _fireDBService.getCategories().first.then((cloudCategories) =>
            _localDBService.addCategories(cloudCategories));
      }
    });
    _localDBService.getPeriods(uid).first.then((localPeriods) {
      if (localPeriods.length == 0) {
        _fireDBService
            .getPeriods()
            .first
            .then((cloudPeriods) => _localDBService.addPeriods(cloudPeriods));
      }
    });
    _localDBService
        .getRecurringTransactions(uid)
        .first
        .then((localRecurringTransactions) {
      if (localRecurringTransactions.length == 0) {
        _fireDBService.getRecurringTransactions().first.then(
            (cloudRecurringTransactions) => _localDBService
                .addRecurringTransactions(cloudRecurringTransactions));
      }
    });
    _localDBService.getPreferences(uid).first.then((localPreferences) {
      if (localPreferences == null) {
        _fireDBService.getPreferences().first.then((cloudPreferences) =>
            _localDBService.addPreferences(cloudPreferences));
      }
    });
  }
}
