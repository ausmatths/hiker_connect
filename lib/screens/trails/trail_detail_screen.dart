// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:hiker_connect/models/trail_data.dart';
// import 'package:hiker_connect/services/databaseservice.dart';
// import 'package:hiker_connect/utils/logger.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:hiker_connect/utils/async_context_handler.dart';
// import 'event_edit_screen.dart';
//
// class TrailDetailScreen extends StatefulWidget {
//   final String trailName;
//
//   const TrailDetailScreen({
//     super.key,
//     required this.trailName,
//   });
//
//   @override
//   State<TrailDetailScreen> createState() => _TrailDetailScreenState();
// }
//
// class _TrailDetailScreenState extends State<TrailDetailScreen> {
//   bool _isLoading = true;
//   bool _isJoined = false;
//   TrailData? _trail;
//   late DatabaseService _dbService;
//   String? _error;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _dbService = Provider.of<DatabaseService>(context, listen: false);
//     _loadTrailDetails();
//   }
//
//   Future<void> _loadTrailDetails() async {
//     AsyncContextHandler.safeAsyncOperation(
//       context,
//           () async {
//         setState(() {
//           _isLoading = true;
//           _error = null;
//         });
//
//         final trail = await _dbService.getTrailByName(widget.trailName);
//         setState(() {
//           _trail = trail;
//           _isLoading = false;
//         });
//       },
//       onError: (error) {
//         AppLogger.error('Failed to load trail details: ${error.toString()}');
//         setState(() {
//           _error = 'Could not load trail details: ${error.toString()}';
//           _isLoading = false;
//         });
//       },
//     );
//   }
//
//   void _toggleJoinEvent() {
//     setState(() {
//       _isJoined = !_isJoined;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(_isJoined
//               ? 'You have joined ${_trail?.trailName}'
//               : 'You have unjoined ${_trail?.trailName}'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     });
//   }
//
//   Future<void> _editTrail() async {
//     if (_trail == null) return;
//
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EventEditScreen(
//           event: _trail!,
//           onUpdate: (updatedTrail) {
//             setState(() {
//               _trail = updatedTrail;
//             });
//           },
//           onDelete: () {
//             Navigator.pop(context);
//             Navigator.pop(context, true); // Pass true to indicate deletion
//           },
//         ),
//       ),
//     );
//
//     // Refresh trail data
//     _loadTrailDetails();
//   }
//
//   Future<void> _shareTrail() async {
//     AsyncContextHandler.safeAsyncOperation(
//       context,
//           () async {
//         // Placeholder for sharing functionality
//         await Future.delayed(const Duration(milliseconds: 500));
//         return Future.value();
//       },
//       onSuccess: () {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Sharing functionality coming soon!'),
//           ),
//         );
//       },
//       onError: (error) {
//         AppLogger.error('Error sharing trail: ${error.toString()}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Error sharing trail'),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.trailName)),
//         body: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//
//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.trailName)),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, color: Colors.red, size: 60),
//               const SizedBox(height: 16),
//               Text(
//                 'Error Loading Trail',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               const SizedBox(height: 8),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 32),
//                 child: Text(
//                   _error!,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _loadTrailDetails,
//                 child: const Text('Try Again'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     if (_trail == null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.trailName)),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 60),
//               const SizedBox(height: 16),
//               Text(
//                 'Trail Not Found',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Go Back'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // App Bar with Image
//           SliverAppBar(
//             expandedHeight: 200.0,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               title: Text(_trail!.trailName),
//               background: _trail!.trailImages.isNotEmpty
//                   ? Image.file(
//                 File(_trail!.trailImages.first),
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Container(
//                     color: Colors.grey[300],
//                     child: const Icon(
//                       Icons.image,
//                       size: 80,
//                       color: Colors.white,
//                     ),
//                   );
//                 },
//               )
//                   : Container(
//                 color: Colors.deepPurple[200],
//                 child: const Center(
//                   child: Icon(
//                     Icons.hiking,
//                     size: 80,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.share),
//                 onPressed: _shareTrail,
//                 tooltip: 'Share',
//               ),
//               IconButton(
//                 icon: const Icon(Icons.edit),
//                 onPressed: _editTrail,
//                 tooltip: 'Edit',
//               ),
//             ],
//           ),
//
//           // Trail Content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Trail details card
//                   Card(
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Wrap(
//                             spacing: 8, // gap between adjacent chips
//                             runSpacing: 8, // gap between lines
//                             children: [
//                               Chip(
//                                 label: Text(_trail!.trailDifficulty),
//                                 backgroundColor: _trail!.trailDifficulty == 'Easy'
//                                     ? Colors.green[100]
//                                     : _trail!.trailDifficulty == 'Hard'
//                                     ? Colors.red[100]
//                                     : Colors.orange[100],
//                                 labelStyle: TextStyle(
//                                   color: _trail!.trailDifficulty == 'Easy'
//                                       ? Colors.green[800]
//                                       : _trail!.trailDifficulty == 'Hard'
//                                       ? Colors.red[800]
//                                       : Colors.orange[800],
//                                 ),
//                               ),
//                               Chip(
//                                 label: Text('${_trail!.trailDuration.inHours}h ${_trail!.trailDuration.inMinutes % 60}m'),
//                                 backgroundColor: Colors.blue[100],
//                                 labelStyle: TextStyle(color: Colors.blue[800]),
//                                 avatar: Icon(Icons.timer, size: 16, color: Colors.blue[800]),
//                               ),
//                               Chip(
//                                 label: Text('${_trail!.trailParticipantNumber} Slots'),
//                                 backgroundColor: Colors.purple[100],
//                                 labelStyle: TextStyle(color: Colors.purple[800]),
//                                 avatar: Icon(Icons.people, size: 16, color: Colors.purple[800]),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Description',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             _trail!.trailDescription,
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Details',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           DetailRow(
//                             icon: Icons.location_on,
//                             title: 'Location',
//                             value: _trail!.trailLocation,
//                           ),
//                           DetailRow(
//                             icon: Icons.calendar_today,
//                             title: 'Date',
//                             value: DateFormat.yMMMMd().format(_trail!.trailDate),
//                           ),
//                           if (_trail!.trailNotice.isNotEmpty)
//                             DetailRow(
//                               icon: Icons.info_outline,
//                               title: 'Notice',
//                               value: _trail!.trailNotice,
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Images section
//                   if (_trail!.trailImages.isNotEmpty) ...[
//                     const Text(
//                       'Trail Photos',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       height: 150,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: _trail!.trailImages.length,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 8.0),
//                             child: GestureDetector(
//                               onTap: () {
//                                 // Show full screen image
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) => Dialog(
//                                     insetPadding: EdgeInsets.zero,
//                                     child: GestureDetector(
//                                       onTap: () => Navigator.pop(context),
//                                       child: Container(
//                                         width: double.infinity,
//                                         height: double.infinity,
//                                         color: Colors.black,
//                                         child: InteractiveViewer(
//                                           child: Center(
//                                             child: Image.file(
//                                               File(_trail!.trailImages[index]),
//                                               fit: BoxFit.contain,
//                                               errorBuilder: (context, error, stackTrace) {
//                                                 return const Icon(
//                                                   Icons.broken_image,
//                                                   size: 100,
//                                                   color: Colors.white,
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   File(_trail!.trailImages[index]),
//                                   height: 150,
//                                   width: 150,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return Container(
//                                       height: 150,
//                                       width: 150,
//                                       color: Colors.grey[200],
//                                       child: const Icon(Icons.broken_image),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//
//                   const SizedBox(height: 80), // Space for the button
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _toggleJoinEvent,
//         label: Text(_isJoined ? 'Leave Trail' : 'Join Trail'),
//         icon: Icon(_isJoined ? Icons.remove_circle : Icons.hiking),
//         backgroundColor: _isJoined ? Colors.red : Colors.green,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }
//
// class DetailRow extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String value;
//
//   const DetailRow({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.value,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 20, color: Colors.grey[700]),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }