import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './details_doctor.dart';
import './booking_screen.dart';
import '../providers/auth_notifier.dart';
import '../providers/data_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String? _selectedEspecialidad;
  List<String> _especialidades = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
    _loadEspecialidades();
  }

  Future<void> _loadEspecialidades() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final snapshot = await dataProvider.getItems('medicos').first;
    final especialidadesSet =
        snapshot.docs.map((doc) => doc['especialidad'].toString()).toSet();
    setState(() {
      _especialidades = especialidadesSet.toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 30.0,
          ),
          const Center(
            child: Text(
              "Lista de Medicos",
              style: TextStyle(fontSize: 30.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 16.0, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                DropdownButton<String>(
                  value: _selectedEspecialidad,
                  hint: const Text('Especialidad'),
                  items: _especialidades.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedEspecialidad = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: dataProvider.getItems('medicos'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay datos disponibles'));
                }
                final medicos = snapshot.data!.docs;
                final searchLower = _searchText.toLowerCase();

                final filteredMedicos = medicos.where((medico) {
                  final nombre = medico['nombre'].toString().toLowerCase();
                  final apellidoP =
                      medico['apellido_paterno'].toString().toLowerCase();
                  final apellidoM =
                      medico['apellido_materno'].toString().toLowerCase();
                  final especialidad =
                      medico['especialidad'].toString().toLowerCase();

                  final matchesSearch = nombre.contains(searchLower) ||
                      apellidoP.contains(searchLower) ||
                      apellidoM.contains(searchLower) ||
                      "$nombre $apellidoP $apellidoM".contains(searchLower);
                  final matchesEspecialidad = _selectedEspecialidad == null ||
                      especialidad
                          .contains(_selectedEspecialidad!.toLowerCase());

                  return matchesSearch && matchesEspecialidad;
                }).toList();

                return ListView.builder(
                  itemCount: filteredMedicos.length,
                  itemBuilder: (context, index) {
                    final medico = filteredMedicos[index];
                    final medicoId = medico.id;
                    final nombre = medico['nombre'];
                    final especialidad = medico['especialidad'];
                    final apellidoP = medico['apellido_paterno'];
                    final apellidoM = medico['apellido_materno'];

                    return Container(
                      margin: const EdgeInsets.all(9.0),
                      padding: const EdgeInsets.all(9.0),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1.0,
                            color: Colors.grey,
                          ),
                          top: BorderSide(width: 1.0, color: Colors.grey),
                        ),
                      ),
                      child: ListTile(
                        title: Text("Medico: $nombre $apellidoP $apellidoM"),
                        subtitle: Text("Especialidad: $especialidad"),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DetailsDoctor(
                                medicoId: medicoId,
                                nombre: nombre,
                                apellidoP: apellidoP,
                                apellidoM: apellidoM,
                                especialidad: especialidad,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: _buildUserInfo(authProvider),
            ),
            ListTile(
              title: const Text("Reservas"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookingScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text("Doctores"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Cerrar Sesión"),
              onTap: () async {
                await authProvider.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(AuthProvider authProvider) {
    final user = authProvider.user?.email;
    if (user == null) {
      return const Text('No hay usuario conectado actualmente.');
    }
    final displayName = user;
    return Text(displayName);
  }
}
