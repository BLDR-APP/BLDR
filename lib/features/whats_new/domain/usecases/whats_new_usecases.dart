import 'package:bldr_fitness/features/whats_new/data/whats_new_datasource.dart';
import 'package:bldr_fitness/features/whats_new/domain/entities/whats_new_entity.dart';

class GetWhatsNew {
  final WhatsNewDatasource _ds;
  const GetWhatsNew(this._ds);
  Future<WhatsNewData?> call() => _ds.fetchIfUnseen();
}

class MarkWhatsNewSeen {
  final WhatsNewDatasource _ds;
  const MarkWhatsNewSeen(this._ds);
  Future<void> call(String id) => _ds.markAsSeen(id);
}
