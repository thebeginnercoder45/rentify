const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin with your service account
// You'll need to create a service account private key from Firebase Console
// Project settings > Service accounts > Generate new private key
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

// Sample car data as specified in FIRESTORE_SETUP.md
const cars = [
  {
    model: "Tesla Model 3",
    distance: 15.5,
    fuelCapacity: 100.0,
    pricePerHour: 25.0
  },
  {
    model: "Toyota Camry",
    distance: 20.0,
    fuelCapacity: 60.0,
    pricePerHour: 15.0
  },
  {
    model: "Honda Civic",
    distance: 18.0,
    fuelCapacity: 50.0,
    pricePerHour: 12.0
  },
  {
    model: "BMW X5",
    distance: 25.0,
    fuelCapacity: 80.0,
    pricePerHour: 30.0
  },
  {
    model: "Mercedes-Benz E-Class",
    distance: 22.0,
    fuelCapacity: 70.0,
    pricePerHour: 35.0
  }
];

async function addCarsToFirestore() {
  try {
    console.log('Adding cars to Firestore...');
    
    // Create a batch to add all cars at once
    const batch = db.batch();
    
    // Add each car to the batch
    for (const car of cars) {
      const carRef = db.collection('cars').doc();
      batch.set(carRef, car);
      console.log(`Added car: ${car.model}`);
    }
    
    // Commit the batch
    await batch.commit();
    
    console.log('All cars added successfully!');
  } catch (error) {
    console.error('Error adding cars to Firestore:', error);
  }
}

// Run the function
addCarsToFirestore(); 