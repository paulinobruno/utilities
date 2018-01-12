-- Find relation between Jobs and Transformations
SELECT j."NAME" nm_job, 'is using ', t."NAME" nm_transformation
FROM r_job j
  JOIN r_jobentry je ON je.id_job = j.id_job
  JOIN r_jobentry_attribute jea ON jea.id_jobentry = je.id_jobentry
  JOIN r_transformation t ON jea.value_str::int = t.id_transformation
WHERE jea.code = 'trans_object_id';
