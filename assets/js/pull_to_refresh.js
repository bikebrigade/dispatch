export default function () {
  // Track touch events on the document
  document.addEventListener("touchstart", handleTouchStart, false);
  document.addEventListener("touchmove", handleTouchMove, false);

  var startY; // Initial Y coordinate of touch event

  function handleTouchStart(event) {
    // Store the initial Y coordinate of the touch event
    startY = event.touches[0].clientY;
  }

  function handleTouchMove(event) {
    if (document.body.scrollTop === 0) {
      // User is at the top of the page
      var currentY = event.touches[0].clientY;
      var deltaY = currentY - startY;

      if (deltaY > 50) {
        // User has pulled down more than 50px
        // Trigger refresh action here
        location.reload(); // Reload the page for demonstration purposes
      }
    }
  }
}
