# Happily Ever After

The **Happily Ever After** is a complete Ruby on Rails application designed to help couples manage their wedding events, including family RSVPs, gift lists, and guest communication. This system is modern, responsive, and styled with **Tailwind CSS** to provide a seamless user experience. The project integrates advanced functionalities like background job processing, user authentication, and rich interactivity using **Hotwire**.

## Key Features

### 1. **Family Management**
- Allows the admin to create and manage families.
- Each family can include multiple members with details like name, age, and gender.
- Generates unique access tokens for families to confirm their presence.

### 2. **RSVP Management**
- Families can log in using their unique access tokens to confirm attendance.
- View and select which family members will attend.
- Option to decline the invitation with a simple interaction.

### 3. **Gift List Management**
- Admin can create and manage a list of wedding gifts with name, price, and images.
- Guests can view the list and select gifts to purchase or contribute with a custom donation.

### 4. **Guest Experience**
- Beautiful landing page for guests to navigate.
- Dynamic pages for RSVP and gift selection powered by **Hotwire**.

### 5. **Admin Features**
- Authentication for administrators using **Devise**.
- User-friendly admin interface to manage families, gifts, and settings.
- Ability to set RSVP deadlines and track attendance.

### 6. **Integrations**
- Background jobs with **Sidekiq** to handle notifications or reminders.
- Modern JavaScript interactivity with **StimulusJS** and **Turbo**.
- Responsive design with **Tailwind CSS**.

---

## Installation

### Prerequisites
Ensure you have the following installed:
- Ruby 3.3.7
- Rails 8.0.1
- PostgreSQL
- Yarn
- Node.js
- Docker (optional, for containerized setup)

### Steps

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd marriage_system
   ```

2. **Install Dependencies**:
   ```bash
   bundle install
   yarn install
   ```

3. **Set Up the Database**:
   ```bash
   rails db:create db:migrate db:seed
   ```

4. **Start the Server**:
   ```bash
   rails server
   ```

5. **Access the Application**:
   Open your browser and navigate to `http://localhost:3000`.

---

## Docker Setup (Optional)

If you prefer to run the application using Docker:

1. **Build the Containers**:
   ```bash
   docker-compose build
   ```

2. **Start the Containers**:
   ```bash
   docker-compose up
   ```

3. **Set Up the Database**:
   ```bash
   docker-compose run web rails db:create db:migrate db:seed
   ```

4. **Access the Application**:
   Open your browser and navigate to `http://localhost:3000`.

---

## Technologies Used

### Backend
- **Ruby on Rails**: Web framework.
- **PostgreSQL**: Database.
- **Sidekiq**: Background job processing.

### Frontend
- **Tailwind CSS**: For responsive and modern styling.
- **Hotwire**: Combines Turbo and Stimulus for rich interactivity.
- **Simple Form**: Simplifies form creation and customization.

### Deployment and DevOps
- **Docker**: Containerized development and production setup.
- **Kamal**: Deployment tool for Dockerized Rails apps.

---

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b my-new-feature`.
3. Commit your changes: `git commit -m 'Add some feature'`.
4. Push to the branch: `git push origin my-new-feature`.
5. Submit a pull request.

---

## License

This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
For full license text, see the [LICENSE](./LICENSE) file.

You are free to use and adapt this project for personal or educational purposes. Commercial use is prohibited.

---

## Acknowledgments
Special thanks to:
- **Devise** and **Pundit** for making authentication and authorization easy.
- **Simple Form** and **Tailwind CSS** for seamless styling and user experience.
- **Rails Community** for constant support and resources.

---

With this system, we hope to make wedding planning less stressful and more enjoyable for everyone involved.
