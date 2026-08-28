import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  // Configuração do Singleton
  ExportService._privateConstructor();
  static final ExportService instance = ExportService._privateConstructor();

  /// Exporta os dados para um arquivo CSV e abre a tela de compartilhamento
  Future<void> exportToCsv(List<Map<String, dynamic>> data) async {
    try {
      List<String> rows = [];

      // Cabeçalho do CSV
      rows.add("Data,Tipo,Valor,Unidade,Notas");

      // Preenche os dados
      for (var item in data) {
        // Limpando os dados para evitar quebras no CSV
        final date = item['measured_at']?.toString().split('T').first ?? '';
        final type = item['type']?.toString() ?? '';
        final value = item['value']?.toString() ?? '';
        final unit = item['unit']?.toString() ?? '';
        final notes = item['notes']?.toString().replaceAll(',', ';') ?? ''; // Troca vírgula por ponto e vírgula

        rows.add("$date,$type,$value,$unit,$notes");
      }

      // Junta tudo em uma única string
      String csvData = rows.join('\n');

      // Pega o diretório temporário do dispositivo para salvar o arquivo
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/relatorio_progresso.csv';
      final file = File(path);

      // Escreve o arquivo
      await file.writeAsString(csvData);

      // Compartilha o arquivo
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Aqui está meu relatório de progresso!',
      );
    } catch (e) {
      debugPrint('Erro ao exportar CSV: $e');
      rethrow;
    }
  }

  /// Exporta os dados para um arquivo PDF e abre a tela de compartilhamento
  Future<void> exportToPdf(List<Map<String, dynamic>> data) async {
    try {
      final pdf = pw.Document();

      // Mapeia os dados para o formato de tabela do PDF
      final tableData = data.map((item) {
        final date = item['measured_at']?.toString().split('T').first ?? '';
        final type = item['type']?.toString() ?? '';
        final value = item['value']?.toString() ?? '';
        final unit = item['unit']?.toString() ?? '';
        final notes = item['notes']?.toString() ?? '';

        return [date, type, value, unit, notes];
      }).toList();

      // Adiciona uma página ao PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Relatório de Progresso',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                headers: <String>['Data', 'Tipo', 'Valor', 'Unidade', 'Notas'],
                data: tableData,
              ),
            ];
          },
        ),
      );

      // Pega o diretório e salva o PDF
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/relatorio_progresso.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      // Compartilha o PDF
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Confira minha evolução recente!',
      );
    } catch (e) {
      debugPrint('Erro ao exportar PDF: $e');
      rethrow;
    }
  }

  /// Compartilha um texto de resumo rápido nas redes sociais ou WhatsApp
  Future<void> shareSummary(int val1, int val2) async {
    try {
      // Como na tela você está passando (0, 0), deixei uma mensagem de compartilhamento
      // padrão focada no marketing do app. Você pode ajustar os parâmetros futuramente.
      const String message = "Construa sua melhor versão! Acompanhe minha evolução no app BLDR. 🐆💪";

      await Share.share(message);
    } catch (e) {
      debugPrint('Erro ao compartilhar resumo: $e');
      rethrow;
    }
  }
}