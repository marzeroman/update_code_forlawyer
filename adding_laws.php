<?php
// Database connection
$servername = "localhost";
$username = "your_username";
$password = "your_password"; // Store password securely
$dbname = "lawyermanagement";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}

// Handle form submission
if ($_SERVER["REQUEST_METHOD"] == "POST") {

  // Validate law text
  $law_text = trim($_POST["law_text"]);
  if (empty($law_text) || strlen($law_text) > 500) {
    $error_message = "Law text is required and must be less than 500 characters.";
  }

  // Validate category
  $category = trim($_POST["category"]);
  if (empty($category) || !in_array($category, ["Iraq", "Kurdistan"])) {
    $error_message = "Please select a valid category.";
  }

  // No errors, proceed with insertion
  if (empty($error_message)) {

    // Sanitize user input
    $law_text = filter_var($law_text, FILTER_SANITIZE_STRING);
    $category = filter_var($category, FILTER_SANITIZE_STRING);

    // SQL query to insert a new law with prepared statement
    $sql = "INSERT INTO laws (law_text, category, creation_date) VALUES (?, ?, NOW())";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $law_text, $category);

    if ($stmt->execute()) {
      // Success, redirect to confirmation page
      header("Location: success.php");
      exit;
    } else {
      $error_message = "Error adding law: " . $stmt->error;
    }

    $stmt->close();
  }
}

$conn->close();
?>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Add Law</title>
</head>
<body>
  <h1>Add a New Law</h1>
  <?php if (isset($error_message)): ?>
    <p class="error"><?php echo $error_message; ?></p>
  <?php endif; ?>
  <form method="POST" action="<?php echo $_SERVER['PHP_SELF']; ?>">
    <label for="law_text">Law Text:</label>
    <textarea name="law_text" id="law_text" rows="4" cols="50" required></textarea><br><br>

    <label for="category">Category:</label>
    <select name="category" id="category" required>
      <option value="Iraq">Iraq</option>
      <option value="Kurdistan">Kurdistan</option>
    </select><br><br>

    <input type="submit" value="Add Law">
  </form>
</body>
</html>

**Improvements:**

* **Validation:** Added checks for law text length and category selection.
* **Sanitization:** Implemented `filter_var` to sanitize user input before insertion.
* **Error handling:** Improved error message and displayed it above the form.
* **Success handling:** Redirected to a dedicated success page (`success.php`) upon successful insertion.
* **Password security:** Highlighted the importance of storing passwords securely.
* **Category flexibility:** You can modify the `$category` list to allow for custom category additions.
* **Additional fields:** You can add more fields to the form based on your specific needs.

This improved version provides a more secure and user-friendly experience for adding laws to your system. Remember to create the `success.php` page with appropriate information or options as mentioned in the code.