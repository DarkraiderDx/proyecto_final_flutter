import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_notifier.dart';
import '../providers/data_notifier.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final userEmail = authProvider.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservas"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataProvider.getItems('reservas'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay reservas disponibles'));
          }

          final reservas = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['patientEmail'] == userEmail;
          }).toList();

          final now = DateTime.now();
          final reservasFuturas = reservas.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['date'] as Timestamp).toDate().isAfter(now);
          }).toList();
          final reservasPasadas = reservas.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['date'] as Timestamp).toDate().isBefore(now);
          }).toList();

          return Column(
            children: [
              const SizedBox(height: 16.0),
              const Text(
                'Reservas Futuras',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: reservasFuturas.isNotEmpty
                    ? ListView.builder(
                        itemCount: reservasFuturas.length,
                        itemBuilder: (context, index) {
                          final reserva = reservasFuturas[index];
                          final data = reserva.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['medicoNombre']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Paciente: ${data['patientName']}'),
                                Text(
                                    'Fecha: ${data['date'].toDate().toLocal()}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _editReservation(context, reserva);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    await dataProvider.deleteItem(
                                        'reservas', reserva.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(child: Text('No hay reservas futuras')),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Reservas Pasadas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: reservasPasadas.isNotEmpty
                    ? ListView.builder(
                        itemCount: reservasPasadas.length,
                        itemBuilder: (context, index) {
                          final reserva = reservasPasadas[index];
                          final data = reserva.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['medicoNombre']),
                            subtitle: Text(
                                'Fecha: ${data['date'].toDate().toLocal()}'),
                          );
                        },
                      )
                    : const Center(child: Text('No hay reservas pasadas')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editReservation(
      BuildContext context, DocumentSnapshot reserva) async {
    final TextEditingController _patientNameController =
        TextEditingController();
    final TextEditingController _dateController = TextEditingController();
    final data = reserva.data() as Map<String, dynamic>;
    _patientNameController.text = data['patientName'] ?? '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paciente: ${data['patientName']}'),
              const SizedBox(height: 10),
              TextField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nuevo Nombre del Paciente',
                ),
              ),
              const SizedBox(height: 10),
              Text('Fecha Actual: ${data['date'].toDate().toLocal()}'),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final DateTime? newDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (newDate != null) {
                    _dateController.text = newDate.toString().split(' ')[0];
                  }
                },
                child: const Text('Cambiar Fecha'),
              ),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva Fecha',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newData = {
                  'patientName': _patientNameController.text.trim(),
                  'date':
                      Timestamp.fromDate(DateTime.parse(_dateController.text)),
                };
                await Provider.of<DataProvider>(context, listen: false)
                    .updateReservation('reservas', reserva.id, newData);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reserva actualizada')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        );
      },
    );
  }
}
