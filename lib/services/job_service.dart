import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add job
  Future<void> addJob(JobModel job) async {
    await _db.collection("jobs").add(job.toMap());
  }

  // Get all jobs
  Future<List<JobModel>> getJobs() async {
    final snap = await _db
        .collection("jobs")
        .orderBy("createdAt", descending: true)
        .get();

    return snap.docs
        .map((d) => JobModel.fromMap(d.data(), d.id))
        .toList();
  }

  // Update job
  Future<void> updateJob(String id, Map<String, dynamic> data) async {
    await _db.collection("jobs").doc(id).update(data);
  }

  // Delete job
  Future<void> deleteJob(String id) async {
    await _db.collection("jobs").doc(id).delete();
  }
}
