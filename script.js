const counter = document.querySelector(".counter-number");
async function updateCounter() {
    let response = await fetch(
        "https://vwtm2qu7shjaqqz7vo3qxo32hi0kfdds.lambda-url.us-east-1.on.aws/"
    );
    let data = await response.json();
    counter.innerHTML = `Webpage Views: ${data}`;
}
updateCounter();