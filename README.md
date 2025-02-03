##Hiker Connect App Design

**Team Member: Austin Matthews, Navami Bhat and Shrinkhla Sinha.**

**Major Features (Priority Order)**

**Essential Features:**

Trail Database & Search – The feature provides users with the option to search and view trail information. We consider this as the app's core function as it allows maintaining a trail database and helps discover new hiking locations for users.

User Profile System (with role management) - A user profile feature is essential for user registration and login to authenticate genuine users, and it can also help differentiate between a regular user and a content curator.

Event Creation & Management - Core functionality of this feature is organizing hikes picking the date and time, setting where to meet, and managing participants.

**Nice to Have Features:**

1. Trail Reviews & Ratings - Users can share their hiking experiences which helps other users to make an informed decision on selecting a hiking location.

2. Photo Gallery – A feature that helps users to share pictures from hikes or trail locations that provides a clear picture on the trail conditions.

3. Bookmarks - This feature allows users to save favorite trails and events so the users can save it for future reference and do not have to search for them every time.

4. Achievement tracker- Tracks user hiking milestones and accomplishments.

**User Activities**

Story - Creating a Hiking Event (Navami Bhat):

Sarah is a fitness enthusiast and wants to plan a short hike to Franklin falls with a group of friends. She signs in to the Hiker Connect App with a registered email and password, In the navigation bar of home screen, she taps the “Events” icon to navigate to create events page. She clicks a “+” icon to create a new event which renders a form. She fills the event form by first selecting a trail named "Franklin Falls" from the trail database, which populates the information such as trail difficulty and location. Sarah gives a name for the event as “Franklin Falls Chronicles” selects a date from the calendar and sets the event time as 9 AM and specifies a meeting point as “Franklin falls trailhead parking lot” by filling the comments field of the events form. She now sets the participant limit to 8 and an RSVP deadline of Friday evening. After reviewing the filled form having the event details, she taps then taps on "Create Event" at the end of the form, she sees a pop up of event confirmation, that says, “Franklin Falls Chronicles Event Created!”. Sarah can now view the event created by her on the Events screen and it will also now appear under "My Upcoming Events" on the Home Page. She can also select the event and can select from the option to share her event on Social Media platforms.


**Trail Content Curation (Austin Matthews):**

Story:

A content curator logs into the app to update information about a trail he recently inspected. From the home screen, he selects "Manage Trails" from the curator dashboard. He searches for "Rattlesnake Ridge" and selects it from the results. The trail details page opens in edit mode, allowing him to update current conditions. He adds a notice about recent washout on the trail's second mile and updates the difficulty rating to "Moderate" due to the condition. He uploads two new photos showing the washout area and adds a warning about required waterproof footwear. After reviewing his changes in the preview screen, he submits the updates. The app shows a confirmation message and immediately publishes the changes to all users.


**Event Participation (Shrinkhla Sinha):**

Story:

Tom wants to go on a hiking trip for the weekend, so he opens the Hiker Connect app to look for upcoming hikes. He goes to the Events section, where all the public hikes are listed. He uses filters to look for medium-difficulty hikes. A group hike to Mount Rainier catches his attention, so he clicks on it to see more details. He reads about the hike, learns what gear he will need, and checks the weather forecast for the day of the hike. After reviewing all the information and deciding it’s a good option, he clicks the "Join Event" button. Since he is already registered on the app, he immediately gets confirmation that he has joined the hike.


**Milestone Planning

**Milestone 1: Core User Features**

* Create the trail viewing interface where users can:
1. Browse the list of available trails
2. View detailed trail information
3. Add new trails to the database
4. Update trail conditions and details

* Implement basic authentication allowing users to:
1. Sign up with email and password
2. Create a basic profile with name and emergency contact
3. Log in and out of the application

Success Criteria:
* Users can successfully create accounts and log in
* Users can view, add, and update trail information
* Trail data persists between app sessions

**Milestone 2: Event Management**

* Develop event creation features enabling users to:
1. Create new hiking events
2. Select trails from the database for events
3. Set event details (date, time, meeting point)
4. Specify participant limits and RSVP deadlines

* Build event participation features allowing users to:
1. Browse available events
2. Join events
3. View their upcoming events
4. Receive event confirmations

Success Criteria:
* Users can create and manage hiking events
* Users can successfully join events
* Event details are accurately displayed to all participants

**Milestone 3: Enhanced Features**

* Implement the photo gallery feature to:
1. Allow users to upload trail photos
2. Display photos on trail detail pages
3. Let users browse trail photo collections

* Add the bookmarking system enabling users to:
1. Save favorite trails
2. Save interesting events
3. Quickly access saved items

* Create the review system allowing users to:
1. Rate trails
2. Write detailed reviews
3. View others' ratings and reviews

Success Criteria:
* Users can successfully upload and view photos
* Bookmarking system works reliably
* Review system provides valuable trail feedback**

* Description: In the final milestone we aim to focus on features that enhance the user experience but aren't critical to core functionality. This gives us flexibility to adjust scope if earlier milestones take longer than expected.

**Risk Mitigation:**

The first and foremost risk which we feel we can face is we are new to the language dart and flutter it can be challenging while developing, particularly in resolving the bugs, to mitigate this so we need to plan and give more time for the features or give extra days than required.

The other risk which we think we can face is reflecting real time changes like new event creation and updates to be instantly reflected across all user devices. The other risk which we face is Ensuring the app works even when the user has no internet connection. We have also identified that we can face issues while user authentication.

If a team member becomes unavailable, our milestones are structured so that core features are evenly distributed among the team. This ensures that other team members can easily take over responsibilities if needed. 
