import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/auth_notifier.dart';
import '../providers/data_notifier.dart';

class DetailsDoctor extends StatefulWidget {
  final String medicoId;
  final String nombre;
  final String apellidoP;
  final String apellidoM;
  final String especialidad;

  const DetailsDoctor({
    super.key,
    required this.medicoId,
    required this.nombre,
    required this.apellidoP,
    required this.apellidoM,
    required this.especialidad,
  });

  @override
  State<DetailsDoctor> createState() => _DetailsDoctorState();
}

class _DetailsDoctorState extends State<DetailsDoctor> {
  final TextEditingController _patientNameController = TextEditingController();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();

  Future<void> _makeReservation(BuildContext context, String patientName,
      String email, DateTime selectedDay) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    final formattedDate = selectedDay.toLocal().toString().split(' ')[0];
    final currentReservations = await dataProvider.countReservationsForMedico(
        widget.medicoId, formattedDate);
    const maxReservations = 10;

    if (currentReservations < maxReservations) {
      final reservation = {
        'medicoId': widget.medicoId,
        'medicoNombre':
            '${widget.nombre} ${widget.apellidoP} ${widget.apellidoM}',
        'patientName': patientName,
        'patientEmail': email,
        'timestamp': Timestamp.now(),
        'date': selectedDay, // Guarda la fecha seleccionada
      };

      await dataProvider.addReservation(reservation);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva realizada con éxito')),
      );
      _patientNameController.clear();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cupos disponibles')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userEmail = authProvider.user?.email ?? 'Sin correo electrónico';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Médico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20.0),
            Text(
              'Médico: ${widget.nombre} ${widget.apellidoP} ${widget.apellidoM}',
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 10.0),
            Text(
              'Especialidad: ${widget.especialidad}',
              style: const TextStyle(fontSize: 20.0),
            ),
            TableCalendar(
              calendarFormat: _calendarFormat,
              focusedDay: _selectedDay,
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _patientNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Paciente',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                if (_patientNameController.text.isNotEmpty) {
                  final patientName = _patientNameController.text;
                  await _makeReservation(
                      context, patientName, userEmail, _selectedDay);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, ingrese su nombre')),
                  );
                }
              },
              child: const Text('Reservar'),
            ),
          ],
        ),
      ),
    );
  }
}
