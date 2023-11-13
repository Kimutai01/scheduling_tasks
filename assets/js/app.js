// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

let Hooks = {};
Hooks.QrCode = {
  mounted() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 180,
      height: 180,
    });

    function makeCode() {
      let elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      // SESTSH25479084197920231105123552;- order number
      // SESTKK25479084197920231105103844;- ticket number
      console.log(elText.value);

      if (elText.value.includes("SESTSH")) {
        qrcode.makeCode("http://localhost:4000/orders/" + elText.value);
      } else {
        qrcode.makeCode("http://localhost:4000/tickets/" + elText.value);
      }
    }

    makeCode();
  },
  updated() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 200,
      height: 200,
    });

    function makeCode() {
      var elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      qrcode.makeCode("http://localhost:4000/tickets/" + elText.value);
    }

    makeCode();
  },
};

Hooks.Swiper = {
  mounted() {
    const swiper = new Swiper(".swiper", {
      // Optional parameters
      direction: "horizontal",
      loop: true,
      autoplay: {
        delay: 5000, // Autoplay delay in milliseconds (5 seconds in this example)
      },

      // If we need pagination

      // Navigation arrows

      // Responsive breakpoints
      breakpoints: {
        // when window width is >= 768px (desktop)
        768: {
          slidesPerView: 3,
        },
        // when window width is < 768px (mobile)
        0: {
          slidesPerView: 1,
        },
      },
    });
  },
};

Hooks.Countdown = {
  mounted() {
    // Set the date we're counting down to
    var countDownDate = new Date("Oct 30, 2023 14:00:00").getTime();

    // Update the count down every 1 second
    var x = setInterval(function () {
      // Get today's date and time
      var now = new Date().getTime();

      // Find the distance between now and the count down date
      var distance = countDownDate - now;

      // Time calculations for days, hours, minutes and seconds
      var days = Math.floor(distance / (1000 * 60 * 60 * 24));
      var hours = Math.floor(
        (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
      );
      var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((distance % (1000 * 60)) / 1000);

      // Display the result in the element with id="demo"

      document.getElementById("days").innerHTML = days;
      document.getElementById("hours").innerHTML = hours;
      document.getElementById("minutes").innerHTML = minutes;
      document.getElementById("seconds").innerHTML = seconds;

      // If the count down is finished, write some text
    }, 1000);
  },
};

Hooks.Scroll = {
  mounted() {
    const navigation = document.querySelector(".transparent");
    const windowHeight = window.innerHeight;

    function handleScroll() {
      const scrollTop = window.scrollY;

      const opacity = Math.min(scrollTop / windowHeight, 1);
      navigation.style.backgroundColor = `rgba(0, 0, 0, ${opacity})`;
    }

    // Attach scroll event listener
    window.addEventListener("scroll", handleScroll);
  },
};

Hooks.NavScroll = {
  mounted() {
    const navigation = document.querySelector(".navtransparent");
    const windowHeight = window.innerHeight;

    function handleScroll() {
      const scrollTop = window.scrollY;

      const opacity = Math.min(scrollTop / windowHeight, 1);
      navigation.style.backgroundColor = `rgba(0, 0, 0, ${opacity})`;
    }

    // Attach scroll event listener
    window.addEventListener("scroll", handleScroll);
  },
};

Hooks.Navbar = {
  mounted() {
    const toggleButton = document.getElementById("toggleButton");
    const sidebar = document.getElementById("sidebar");

    toggleButton.addEventListener("click", () => {
      sidebar.classList.toggle("-translate-x-full");
    });

    document.getElementById("sidebarContent").addEventListener("click", () => {
      sidebar.classList.toggle("-translate-x-full");
    });
  },
};
Hooks.Copy = {
  mounted() {
    const copyButtons = document.querySelectorAll(".clipboardCopy");

    copyButtons.forEach((button) => {
      button.addEventListener("click", clipboardCopy);
    });

    async function clipboardCopy(event) {
      const button = event.target;
      const parentTd = button.parentElement;
      const textInput = parentTd.querySelector(".copyable");
      Toastify({
        text: "Copied to clipboard",
        className: "info",
        style: {
          background: "linear-gradient(to right, #00b09b, #96c93d)",
        },
        duration: 2000,
      }).showToast();

      if (textInput) {
        const text = textInput.value;
        await navigator.clipboard.writeText(text);
      }
    }
  },
};

// Hooks.Map = {
//   mounted() {
//     // ADD YOUR ACCESS TOKEN FROM
//     // https://account.mapbox.com
//     mapboxgl.accessToken =
//       "pk.eyJ1IjoiYW5uZXRvdG9oIiwiYSI6ImNsYjB2cDl1dzFrOTQzcHFtOWdxcHBjbGgifQ.LADz9TYffPhRsjZ_O_hUHw";
//     const defaultPointA = [36.8219, 1.2921]; // Default point A [lng, lat]
//     const pointB = [-74.5, 40]; // Default point B [lng, lat]

//     const map = new mapboxgl.Map({
//       container: "map", // container ID
//       // Choose from Mapbox's core styles, or make your own style with Mapbox Studio
//       style: "mapbox://styles/mapbox/streets-v12", // style URL
//       center: defaultPointA, // starting position [lng, lat]
//       zoom: 9, // starting zoom
//     });

//     const directions = new MapboxDirections({
//       accessToken: mapboxgl.accessToken,
//       unit: "metric",
//       profile: "mapbox/driving-traffic",
//       controls: {
//         inputs: true,
//       },
//       waypoints: [
//         { coordinates: pointB }, // Set default point B
//       ],
//     });

//     // Add a static marker for point B
//     new mapboxgl.Marker().setLngLat(pointB).addTo(map);

//     // Add a static marker for point C ([-74.5, 40])
//     new mapboxgl.Marker().setLngLat([-74.5, 40]).addTo(map);

//     map.addControl(directions, "top-left");

//     // Create a draggable marker for point A in the directions control
//     directions.on("load", () => {
//       const pointAMarker = new mapboxgl.Marker({
//         draggable: true,
//       })
//         .setLngLat(defaultPointA)
//         .addTo(map);

//       pointAMarker.on("dragend", () => {
//         const newPointA = pointAMarker.getLngLat();
//         directions.setOrigin(newPointA);
//       });

//       const canvas = directions._container.querySelector(
//         ".mapbox-directions-origin"
//       );
//       canvas.appendChild(pointAMarker.getElement());
//     });
//   },
// };

Hooks.Map = {
  mounted() {
    // ADD YOUR ACCESS TOKEN FROM
    // https://account.mapbox.com
    mapboxgl.accessToken =
      "pk.eyJ1IjoiYW5uZXRvdG9oIiwiYSI6ImNsYjB2cDl1dzFrOTQzcHFtOWdxcHBjbGgifQ.LADz9TYffPhRsjZ_O_hUHw";
    const map = new mapboxgl.Map({
      container: "map", // container ID
      // Choose from Mapbox's core styles, or make your own style with Mapbox Studio
      style: "mapbox://styles/mapbox/streets-v12", // style URL
      center: [36.811667, -1.266944], // starting position [lng, lat]
      zoom: 9, // starting zoom
    });

    // Add a marker to the map
    new mapboxgl.Marker()
      .setLngLat([36.811667, -1.266944]) // marker position [lng, lat]
      .addTo(map);
  },
  updated() {
    // ADD YOUR ACCESS TOKEN FROM
    // https://account.mapbox.com
    mapboxgl.accessToken =
      "pk.eyJ1IjoiYW5uZXRvdG9oIiwiYSI6ImNsYjB2cDl1dzFrOTQzcHFtOWdxcHBjbGgifQ.LADz9TYffPhRsjZ_O_hUHw";
    const map = new mapboxgl.Map({
      container: "map", // container ID
      // Choose from Mapbox's core styles, or make your own style with Mapbox Studio
      style: "mapbox://styles/mapbox/streets-v12", // style URL
      center: [-74.5, 40], // starting position [lng, lat]
      zoom: 9, // starting zoom
    });

    // Add a marker to the map
    new mapboxgl.Marker()
      .setLngLat([-74.5, 40]) // marker position [lng, lat]
      .addTo(map);
  },
};

Hooks.Date = {
  mounted() {
    console.log(
      moment("2023-09-01T08:50:46").format("MMMM Do YYYY, h:mm:ss a")
    );
    document.getElementById("date-of-event").innerText = moment(
      document.getElementById("date-of-event").value
    ).format("MMM Do YYYY");
  },
  updated() {
    document.getElementById("date-of-event").innerText = moment(
      document.getElementById("date-of-event").value
    ).format("MMM Do YYYY");
  },
};

Hooks.EventDate = {
  mounted() {
    document.getElementById("event-date-of-event").innerText = moment(
      document.getElementById("event-date-of-event").value
    ).format("MMM Do YYYY");
  },
  updated() {
    document.getElementById("event-date-of-event").innerText = moment(
      document.getElementById("event-date-of-event").value
    ).format("MMM Do YYYY");
  },
};
Hooks.PromoEventDate = {
  mounted() {
    document.getElementById("promo-event-date-of-event").innerText = moment(
      document.getElementById("promo-event-date-of-event").value
    ).format("MMM Do YYYY");
  },
  updated() {
    document.getElementById("promo-event-date-of-event").innerText = moment(
      document.getElementById("promo-event-date-of-event").value
    ).format("MMM Do YYYY");
  },
};
Hooks.Pdf = {
  mounted() {
    ticket_id = document.getElementById("ticketid").innerHTML;
    window.jsPDF = window.jspdf.jsPDF;
    var docPDF = new jsPDF();
    console.log(screen.width);
    function printLargeTicket() {
      var elementHTML = document.querySelector("#ticket");
      docPDF.html(elementHTML, {
        callback: function (docPDF) {
          docPDF.save("TKKE" + ticket_id + ".pdf");
        },
        x: 10,
        y: 15,
        width: 200,
        windowWidth: 900,
      });
    }

    function printSmallTicket() {
      var elementHTML = document.querySelector("#ticket");
      var docPDF = new jsPDF();

      // Calculate the page dimensions
      var pageWidth = docPDF.internal.pageSize.getWidth();
      var pageHeight = docPDF.internal.pageSize.getHeight();

      // Calculate the dimensions of the content
      var contentWidth = 100; // Replace with your content width
      var contentHeight = 15; // Replace with your content height

      // Calculate the center position
      var x = (pageWidth - contentWidth) / 2;
      var y = (pageHeight - contentHeight) / 2;

      docPDF.html(elementHTML, {
        callback: function (docPDF) {
          docPDF.save(ticket_id + ".pdf");
        },
        x: x,
        y: 15,
        width: contentWidth,
        windowWidth: 300, // Adjust this as needed
      });
    }

    document
      .getElementById("print_large_ticket")
      .addEventListener("click", function () {
        printLargeTicket();
        Toastify({
          text: "Ticket downloaded",
          className: "info",
          style: {
            background: "linear-gradient(to right, #00b09b, #96c93d)",
            marginLeft: "auto",
            marginRight: "auto",
            textAlign: "center",
          },
          duration: 2000,
        }).showToast();
      });

    document
      .getElementById("print_small_ticket")
      .addEventListener("click", function () {
        printSmallTicket();
        Toastify({
          text: "Ticket downloaded",
          className: "info",
          style: {
            background: "linear-gradient(to right, #00b09b, #96c93d)",
            marginLeft: "auto",
            marginRight: "auto",
            textAlign: "center",
          },
          duration: 2000,
        }).showToast();
      });
  },
};

Hooks.Chart = {
  mounted() {
    console.log(document.getElementById("gate_tickets").innerHTML);
    new Chart("myChart", {
      type: "pie",
      color: "white",
      data: {
        labels: ["Gate Tickets", "Online Tickets", "Complimentary Tickets"],
        datasets: [
          {
            label: "Gate ,  Online and Complimentary Tickets",
            data: [
              document.getElementById("gate_tickets").innerHTML,
              document.getElementById("online_tickets").innerHTML,
              document.getElementById("complimentary_tickets").innerHTML,
            ],
            backgroundColor: ["yellow", "green", "blue"],
          },
        ],
      },
    });
  },
};
Hooks.Chart2 = {
  mounted() {
    new Chart("myChart2", {
      type: "doughnut",
      color: "white",
      data: {
        labels: ["Normal Tickets", "Promo Tickets"],
        datasets: [
          {
            label: "Normal and Promo Tickets",
            data: [
              document.getElementById("normal_tickets").innerHTML,
              document.getElementById("promo_tickets").innerHTML,
            ],
            backgroundColor: ["green", "yellow"],
          },
        ],
      },
    });
  },
};

Hooks.Chart3 = {
  mounted() {
    new Chart("myChart3", {
      type: "polarArea",
      color: "white",
      data: {
        labels: ["Early Bird", "Flash Sale ", "Advanced "],
        datasets: [
          {
            label: "Event Tickets",
            data: [
              document.getElementById("early_bird_tickets").innerHTML,
              document.getElementById("flash_sale_tickets").innerHTML,
              document.getElementById("advanced_tickets").innerHTML,
            ],
            backgroundColor: ["red", "green", "yellow"],
          },
        ],
      },
    });
  },
};
Hooks.Chart4 = {
  mounted() {
    // Get an array of promo code names
    const promoCodeNames = Array.from(
      document.querySelectorAll(".promo_code_name")
    ).map((item) => item.innerHTML);

    // Get an array of tickets sold
    const ticketsSoldData = Array.from(
      document.querySelectorAll(".tickets_sold")
    ).map((item) => parseInt(item.innerHTML));

    const randomColors = promoCodeNames.map(() => getRandomColor());

    function getRandomColor() {
      const letters = "0123456789ABCDEF";
      let color = "#";
      for (let i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
      }
      return color;
    }

    // Create a chart
    new Chart("myChart4", {
      type: "bar",
      data: {
        labels: promoCodeNames,
        datasets: [
          {
            label: "PromoCode Tickets",
            data: ticketsSoldData,
            backgroundColor: randomColors,
            borderWidth: 1,
            borderColor: "white",
          },
        ],
      },
      options: {
        scales: {
          y: {
            beginAtZero: true,
          },
        },
      },
    });
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
