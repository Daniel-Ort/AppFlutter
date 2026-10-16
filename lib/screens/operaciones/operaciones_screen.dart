import 'package:flutter/material.dart';

class OperacionesScreen extends StatelessWidget {
  const OperacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de opciones del panel de Operaciones
    final List<Map<String, dynamic>> opciones = [
      {'title': 'Ventas', 'subtitle': 'Salidas', 'icon': Icons.shopping_cart_outlined, 'color': Colors.blue},
      {'title': 'Devoluciones', 'subtitle': 'Salidas', 'icon': Icons.assignment_return_outlined, 'color': Colors.redAccent},
      {'title': 'Traspasos Sal', 'subtitle': 'Salidas', 'icon': Icons.output_outlined, 'color': Colors.purple},
      {'title': 'Compras', 'subtitle': 'Entradas', 'icon': Icons.add_shopping_cart, 'color': Colors.teal},
      {'title': 'Nota de Crédito', 'subtitle': 'Entradas', 'icon': Icons.receipt_long_outlined, 'color': Colors.orange},
      {'title': 'Factura', 'subtitle': 'Documentos', 'icon': Icons.description_outlined, 'color': Colors.indigo},
      {'title': 'Corte de Caja', 'subtitle': 'Caja', 'icon': Icons.point_of_sale_outlined, 'color': Colors.green},
      {'title': 'Artículos', 'subtitle': 'Catálogos', 'icon': Icons.inventory_2_outlined, 'color': Colors.cyan},
      {'title': 'Clientes', 'subtitle': 'Catálogos', 'icon': Icons.people_alt_outlined, 'color': Colors.deepOrange},
      {'title': 'Proveedores', 'subtitle': 'Catálogos', 'icon': Icons.local_shipping_outlined, 'color': Colors.blueGrey},
      {'title': 'Ajuste Inv.', 'subtitle': 'Inventarios', 'icon': Icons.tune_outlined, 'color': Colors.amber},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de Búsqueda y Filtro
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar módulo de operación...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Color(0xFF134E5E)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: 'Todos',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Salidas', child: Text('Salidas')),
                      DropdownMenuItem(value: 'Entradas', child: Text('Entradas')),
                      DropdownMenuItem(value: 'Catálogos', child: Text('Catálogos')),
                    ],
                    onChanged: (val) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Grid de Botones
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: opciones.length,
                itemBuilder: (context, index) {
                  final item = opciones[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        print('Abriendo ${item['title']}');
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: (item['color'] as Color).withOpacity(0.12),
                            child: Icon(item['icon'], color: item['color'], size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            item['subtitle'],
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}