import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive/hive.dart';
import 'package:hiker_connect/models/trail_data.dart'; // Adjust the import path as needed

// Generate mocks for BinaryReader and BinaryWriter
@GenerateMocks([BinaryReader, BinaryWriter])
import 'trail_data_adapter_test.mocks.dart'; // Import the generated mock file

void main() {
  group('TrailDataAdapter Tests', () {
    late TrailDataAdapter adapter;
    late TrailData trailData;
    late MockBinaryReader mockReader;
    late MockBinaryWriter mockWriter;

    setUp(() {
      // Initialize the adapter
      adapter = TrailDataAdapter();

      // Create a sample TrailData object
      trailData = TrailData(
        trailId: 1,
        trailName: 'Mountain Hike',
        trailDescription: 'A challenging hike to the mountain peak.',
        trailDifficulty: 'Hard',
        trailNotice: 'Bring proper hiking gear.',
        trailImages: ['image1.jpg', 'image2.jpg'],
        trailDate: DateTime(2023, 10, 15),
        trailLocation: 'Mountain Trail',
        trailParticipantNumber: 10,
        trailDuration: Duration(hours: 2),
        trailType: 'Hiking',
      );

      // Initialize mocks
      mockReader = MockBinaryReader();
      mockWriter = MockBinaryWriter();
    });

    /*test('read Method', () {
      // Arrange
      when(mockReader.readByte()).thenReturn(11); // Number of fields
      when(mockReader.readByte()).thenReturn(0); // Field index for trailId
      when(mockReader.read()).thenReturn(1); // trailId
      when(mockReader.readByte()).thenReturn(1); // Field index for trailName
      when(mockReader.read()).thenReturn('Mountain Hike'); // trailName
      when(mockReader.readByte()).thenReturn(2); // Field index for trailDescription
      when(mockReader.read()).thenReturn('A challenging hike to the mountain peak.'); // trailDescription
      when(mockReader.readByte()).thenReturn(3); // Field index for trailDifficulty
      when(mockReader.read()).thenReturn('Hard'); // trailDifficulty
      when(mockReader.readByte()).thenReturn(4); // Field index for trailNotice
      when(mockReader.read()).thenReturn('Bring proper hiking gear.'); // trailNotice
      when(mockReader.readByte()).thenReturn(5); // Field index for trailImages
      when(mockReader.read()).thenReturn(['image1.jpg', 'image2.jpg']); // trailImages
      when(mockReader.readByte()).thenReturn(6); // Field index for trailDate
      when(mockReader.read()).thenReturn(DateTime(2023, 10, 15)); // trailDate
      when(mockReader.readByte()).thenReturn(7); // Field index for trailLocation
      when(mockReader.read()).thenReturn('Mountain Trail'); // trailLocation
      when(mockReader.readByte()).thenReturn(8); // Field index for trailParticipantNumber
      when(mockReader.read()).thenReturn(10); // trailParticipantNumber
      when(mockReader.readByte()).thenReturn(9); // Field index for trailDuration
      when(mockReader.read()).thenReturn(Duration(hours: 2)); // trailDuration
      when(mockReader.readByte()).thenReturn(10); // Field index for trailType
      when(mockReader.read()).thenReturn('Hiking'); // trailType

      // Act
      final deserializedTrailData = adapter.read(mockReader);

      // Assert
      expect(deserializedTrailData.trailId, trailData.trailId);
      expect(deserializedTrailData.trailName, trailData.trailName);
      expect(deserializedTrailData.trailDescription, trailData.trailDescription);
      expect(deserializedTrailData.trailDifficulty, trailData.trailDifficulty);
      expect(deserializedTrailData.trailNotice, trailData.trailNotice);
      expect(deserializedTrailData.trailImages, trailData.trailImages);
      expect(deserializedTrailData.trailDate, trailData.trailDate);
      expect(deserializedTrailData.trailLocation, trailData.trailLocation);
      expect(deserializedTrailData.trailParticipantNumber, trailData.trailParticipantNumber);
      expect(deserializedTrailData.trailDuration, trailData.trailDuration);
      expect(deserializedTrailData.trailType, trailData.trailType);
    });*/

    test('write Method', () {
      // Act
      adapter.write(mockWriter, trailData);

      // Assert
      verify(mockWriter.writeByte(11)).called(1); // Number of fields
      verify(mockWriter.writeByte(0)).called(1); // Field index for trailId
      verify(mockWriter.write(trailData.trailId)).called(1);
      verify(mockWriter.writeByte(1)).called(1); // Field index for trailName
      verify(mockWriter.write(trailData.trailName)).called(1);
      verify(mockWriter.writeByte(2)).called(1); // Field index for trailDescription
      verify(mockWriter.write(trailData.trailDescription)).called(1);
      verify(mockWriter.writeByte(3)).called(1); // Field index for trailDifficulty
      verify(mockWriter.write(trailData.trailDifficulty)).called(1);
      verify(mockWriter.writeByte(4)).called(1); // Field index for trailNotice
      verify(mockWriter.write(trailData.trailNotice)).called(1);
      verify(mockWriter.writeByte(5)).called(1); // Field index for trailImages
      verify(mockWriter.write(trailData.trailImages)).called(1);
      verify(mockWriter.writeByte(6)).called(1); // Field index for trailDate
      verify(mockWriter.write(trailData.trailDate)).called(1);
      verify(mockWriter.writeByte(7)).called(1); // Field index for trailLocation
      verify(mockWriter.write(trailData.trailLocation)).called(1);
      verify(mockWriter.writeByte(8)).called(1); // Field index for trailParticipantNumber
      verify(mockWriter.write(trailData.trailParticipantNumber)).called(1);
      verify(mockWriter.writeByte(9)).called(1); // Field index for trailDuration
      verify(mockWriter.write(trailData.trailDuration)).called(1);
      verify(mockWriter.writeByte(10)).called(1); // Field index for trailType
      verify(mockWriter.write(trailData.trailType)).called(1);
    });

    test('Equality and HashCode', () {
      // Create another TrailDataAdapter instance
      final adapter2 = TrailDataAdapter();

      // Verify that the two adapters are equal
      expect(adapter, adapter2);

      // Verify that the hash codes are equal
      expect(adapter.hashCode, adapter2.hashCode);
    });
  });
}