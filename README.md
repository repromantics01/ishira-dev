# PawsMatch

PawsMatch is a Flutter-based application designed to help pet rescue organizations manage pet adoptions, surrender requests, and communications with pet adopters and surrenderers.

<table>
    <tr>
        <th>Internal Release Code</th>
        <th>Date Released</th>
    </tr>
    <tr>
        <td>IS.010.000</td>
        <td>2025-03-12</td>
    </tr>
    <tr>
        <td>IS.010.001</td>
        <td>2025-03-31</td>
    </tr>
    <tr>
        <td>IS.010.002</td>
        <td>2025-04-13</td>
    </tr>
    <tr>
        <td>IS.010.003</td>
        <td>2025-04-16</td>
    </tr>
    <tr>
        <td>IS.010.004</td>
        <td>2025-04-23</td>
    </tr>
    <tr>
        <td>IS.010.005</td>
        <td>2025-04-28</td>
    </tr>
    <tr>
        <td>IS.010.006</td>
        <td>2025-05-13</td>
    </tr>
    <tr>
        <td>...</td>
        <td>...</td>
    </tr>
</table>

## IS.010.006 Release Notes
- Fixed platform compatibility issues for mobile builds
- Implemented conditional imports for web-specific code
- Created platform-specific implementations of web utilities
- Refactored EmailJS integration for better cross-platform support
- Improved error handling for web vs mobile environments
- Introduced modals for pending/rejected verification and updated organization verification logic.
- Updated signup flow to use a unified SignUpFormData and improved navigation.
- Enhanced password reset handling, success dialogs, and improved profile image management and UI consistency.
- Extended models to support profile image URLs and improved parsing helpers.

## IS.010.005 Release Notes
- Enhanced message thread view and application details modal
- Enhanced dashboard to show pet adoption and surrender statistics
- Updated the organization model to include an 'isRejected' field
- Implemented the reject organization feature in the Moderator dashboard with confirmation dialogs
- Enhanced UI for organization details and improved loading/error states
- Added mock data for testing rejected organizations
- UI Completion of the Organization and Moderator interfaces
- Implemented backend services to enhance pet and application management and organization monitoring

## IS.010.004 Release Notes
- Enabled user account and profile editing
- Implemented Firebase services for modifying user account credentials and profile data
- Implemented a complete messaging system between organizations and users
- Added real-time message rendering 
- Created a thread-based conversation interface with date grouping
- Added fallback methods to handle potential Firestore indexing issues
- Implemented proper error handling and loading states
- Created a comprehensive pet management page with search functionality
- Added sorting options (Name, Age, Recently Added)
- Implemented filtering by status (Available, Adopted, Pending, etc.)
- Designed responsive pet card grid with status indicators
- Added empty states with contextual messaging based on filter settings
- Created unified navigation via sidebar
- Added edit functionality for organization details

## IS.010.003 Release Notes
- Implemented filtered pet loading to prevent showing already swiped or adopted pets
- Added swipe inactive state tracking when adoption requests are submitted
- Created a comprehensive adoption request flow connecting swipes to adoption actions
- Improved data fetching with proper error handling for network issues and timeouts
- Enhanced service layer integration between different app features (swipes, adoptions, pets)
- Implemented proper state management to maintain consistency across app views
- Added validation and deduplication to prevent duplicate pet displays
- Created a unified modal system for displaying adoption details with proper data connections

## IS.010.002 Release Notes
- Completed overall implementation of surrendering functionality
- Completed access to relevant information functionality for surrenderer role
- Implementation of adopter's swipe functionality to browse for surrendered pets
- Modified firebase and supabase services to retrieve relevant photo URLs

## IS.010.001 Release Notes
- Completed authentication for both organization and individual users
- Implemented initial UI of individual user pages
- Access to relevant pet organization information
- Modified database configurations for mobile and web 

## IS.010.000 Release Notes
- Database integration
- Implemented initial UI of starter pages
- Configured platform-specific dependencies for mobile and web

## Important Links
- [Design Specs](https://github.com/repromantics01/ishira)
- [Codebase](https://github.com/repromantics01/ishira-dev)
- [Testing Timeline](https://docs.google.com/spreadsheets/d/1liEHsJwp6W05RSp2EH21Xep-ZbhAYTi4ZKHL7sBp9wY/edit?gid=0#gid=0)
