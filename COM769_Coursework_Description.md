# Coursework Overview and Assessment Criteria

**Module Title:** Scalable Advanced Software Solutions
**Module Code:** COM769 (79651)
**Module Coordinator:** Dr Joseph Rafferty
**Teaching Staff Responsible:** Dr Asghar Darvishy
**Semester (s) Taught:** One
**Course / Year Group:** MSc Computer Science
**Coursework / Exam Weighting:** 100/100

## Coursework Assessment Overview
This module is assessed by two pieces of coursework.
* **Coursework 1** consists of a practical skills assessment demonstrating their ability to automatically build, integrate and test source code using common techniques taught within this module. Students will log their experience of this within a 6-page document describing rationale, processes and chosen technologies. Coursework 1 is worth 25% of the overall mark allocation.
* **Coursework 2** is a practical skills assessment wherein students need to develop a solution and create a related presentation plus demonstrative video. Coursework 2 contributes to 75% of the overall mark for this module.

The university has a number of rules and regulations surrounding assessment, late submissions and illness. These are in the student guide [1] - ensure you read this and understand the impact of these rules and regulations. N.B. Students should be aware of the plagiarism policy of the University and submit their coursework in accordance with this.

These coursework assignments are detailed below.

**Note:** Students who submit coursework are declaring the following.
> "I declare that this is all my own work. Any material I have referred to has been accurately referenced and any contribution of Artificial Intelligence technology has been fully acknowledged. I have read the University's policy on academic misconduct and understand the different forms of academic misconduct. If it is shown that material has been falsified, plagiarised, or I have otherwise attempted to obtain an unfair advantage for myself or others, I understand that I may face sanctions in accordance with the policies and procedures of the University. A mark of zero may be awarded and the reason for that mark will be recorded on my file."

**Also note:** You will receive feedback as per University Guidance which is currently set at 20 working days after submission.

---

## Coursework 1 - Practical Skills Assessment [25%]
**Submission Deadline:** During Week 8 Labs
**Feedback Date:** 23 March 2026

**Related learning outcomes:**
1. Develop an appreciation of core concepts related to packaging solutions, continuous integration, continuous delivery, scalable architecture and deployment.

During the delivery course of the module, students will be expected to complete a single 60-minute online test during the week 8 of the semester. The class test should be completed on campus and should be taken from an allocated school of computing lab. Failure to do so will result in a mark of zero. This is open book test, students can access notes, books and lectures. Use of internet at any time is not allowed during the test. Class Test will be based on multiple choice questions, delivered, submitted, and assessed through the Blackboard online learning environment. This test will consist of 30 questions and will incorporate topics taught in lectures and practical exercises, until week 6. There will be no negative marking for the class test. This test will assess depth and systematic understanding of knowledge in specialised areas covered to that point. Feedback from this test will feed-forward into the students continued learning and their execution of the set exercise. Overall Feedback will be provided automatically after 20 working days of the test according to the regulations set by the university feedback guidance.

---

## Coursework 2 - Mini Project [75%]
**Submission Deadline:** 11th May 2026
**Feedback Date:** 8th June 2026

**Related Learning Outcomes:**
1. Demonstrate a comprehensive understanding of modern development and deployment concepts, techniques and practice and how it may be leveraged to address related challenges.
2. Autonomously and independently identify deficiencies when interacting with a range of architectures and deployment paradigms, leveraging knowledge of these deficiencies to improve future practice.
3. Assess the concepts behind a range of modern development and deployment techniques and critically evaluate when to apply these paradigms to realisation of solutions.

Students will be set an exercise where they will be expected to design, develop, and deploy a Scalable Advanced Software Solution in the form of a web app. Specifically for this exercise, students will be expected to perform the following 3 tasks.

### Task 1
*It is possible to complete this coursework to a high standard using only free services. Be aware of the configuration requirements and usage limitations of free services.*

Design, and implement, a scalable, cloud native, web-application which acts as a media distribution website which facilitates sharing of Photos. This application would conceptually be similar to sites such as Instagram.

Ideally, this would enable the following:
* Model "creator" user accounts which may exclusively upload videos to the service; through a dedicated creator view. This includes setting metadata such as Title, Caption, Location and people present. No public interface needs to be offered for enrolment of "creator" users.
* Enable consumer users to use the service with a dedicated consumer view. Consumer users should be able to view/search through image content, view image and comment/rate image. These accounts will not be able to upload image content.

Ideally, this solution would integrate the following:
* Static HTML hosting of content of a web page which interacts with a web backed through REST calls.
* Hosting of a REST endpoint which provides service logic and connections to all necessary elements such as storage.
* Provide persistence of user data through scalable hosted databases and/or block/object storage.
* Cater for user identities and roles using standard authentication mechanisms and user access controls as appropriate for the cloud platform [Optional but recommended].
* Provide scalability mechanisms through appropriate caching and dynamic DNS routing.
* Additionally, media conversion and cognitive services may be used, be aware of the limitations of the free tier services and potential costings.

### Task 2
Implement, deploy, and test the solution designed in task 1. This should be implemented and deployed using the cloud platform explored within the practical exercises associated with this module.

### Task 3
Provide a slide deck which details the developed solution; this slide deck will contain an embedded video where the student provides:
* A 5-minute presentation of the developed, tested and deployed solution. This should focus on the operation of the solution, showing changes and activity on the backend systems.

During this exercise, the student will have demonstrated self-direction and originality in problem solving, acting autonomously in planning and executing this task at a professional level. Additionally, the student will apply technical expertise effectively and will adapt skills previously learnt in conjunction with designing and/or developing new skills or procedures for new situations.

N.B. The students are required to implement this solution using the cloud platform which was the focus of the teaching materials. Once the solution is produced, students are required to produce presentation which incorporates a 5-minute video capture demonstrating the solution.

In the presentation It is recommended to have circa 12 content slides which follow the below outline:
* **Slide 0:** Title Slide. Project name, one line description. Student name, Student number.
* **Slides 1-2:** Discussion of the problem and identification of the issues related to scalability.
* **Slides 3-6:** Overview of the technical solution developed.
* **Slides 7-8:** An overview of advanced features within the developed solution.
* **Slides 9-10:** An assessment of limitations of the solution and evaluation of its ability to scale.
* **Slide 11:** Functionality of the recorded demonstration (15%) [5-minute video]. This needs to showcase the functionality of the solution and show its deployment to the deployment platform such as OpenStack, Amazon Web Services and Azure.
* **Slide 12:** Concluding comments.
* **Slide 13:** References.

Slides should be produced in the PowerPoint format and will need to be uploaded to the relevant assessment area on blackboard.

N.B. NOTE
Students should be aware of the plagiarism policy of the University and submit their coursework in accordance with this. The students are required to implement this solution using the concepts and techniques which were the focus of the teaching materials in this module. This may broadly have a focus on a hosted/cloud native design or a containerised solution. It is recommended that students appraise both these design approaches in their slides.

## References
* https://www.ulster.ac.uk/connect/guide.
* IEEE, "Manuscript Templates for Conference Proceedings." [Online]. Available: https://www.ieee.org/conferences_events/conferences/publishing/templates.html.
* [1] "Ulster University Student Guide." [Online]. Available: [Link missing in original]
* ΙΕΕΕ, "IEEE Citation Reference." [Online]. Available: https://www.ieee.org/documents/ieeecitationref.pdf.
* Mendeley Ltd, "Mendeley Citation Manager." [Online]. Available: https://www.mendeley.com/.

---

## Appendix I - Assessment Criteria Coursework I

| Criteria | Needs improvement [0%-1%] | Satisfactory [2%-3%] | Excellent [4%] | Overall credit [/25] |
| :--- | :--- | :--- | :--- | :--- |
| **Problem Definition and Discussion** | Little description of the overall problem was provided with poor enumeration of issues related to project management, source code revisioning, build processes, deployment and testing. | Moderate description of the overall problem was provided. Moderate enumeration of issues related to project management, source code revisioning, build processes, deployment and testing was provided. | Good description of the overall problem with a good enumeration of issues related to project management, source code revisioning, build processes, deployment and testing. Strong critical appraisal of practices which do not strongly enforce these processes. | 4% |
| **Identified approaches to address problem** | Limited approaches/technologies/processes to address identified issues were identified. Identified approaches were of limited impact. Alternatively, it was unclear, or weakly articulated, how these approaches may be integrated into a production solution. (0-2%) | Some approaches/technologies/processes were identified to address the identified problems. The impact of adoption of these were considered. Some insight into the integration of these approaches into a production solution was articulated. (3-5%) | An extensive range of approaches/technologies/processes were identified to address the identified problems. The impact of adoption of these were considered and justification given for any overheads/adoption penalties. Benefits of the integration of these approaches into a production environment were clearly articulated. (6-7%) | 7% |
| **Solution Design** | An inadequate solution was designed which did not clearly address the problem at hand. (0-2%) | The solution design partly addresses some of the issues related to the problem area. (3-5%) | The solution design addressed the majority of the issues related to the problem area. (6-7%) | 7% |
| **Quantification of solution performance** | No, or Limited, metrics were identified which could be used to quantify the solutions performance. The solution minimally integrated elements to achieve its goals. No, or limited, assessment of these metrics occurred. (0-1%) | A small number of metrics were identified which could be used to quantify the solutions performance. The solution integrated sufficient components to achieve a moderate range of goals. Some assessment of these metrics occurred. (2-3%) | A broad range of metrics were identified which could be used to quantify a solutions performance. The solution integrated sufficient components to the bulk of its goals. A comprehensive assessment of these metrics occurred. (4-5%) | 5% |
| **Concluding comments** | Limited reflection was applied to the solution, its functionality, limitations, and potential applicability. (0%) | Meaningful reflection was applied to the solution, its functionality, limitations, and potential applicability. (1%) | Insightful reflection was applied to the solution, its functionality, limitations, and potential applicability. (2%) | 2% |

---

## Appendix II - Assessment Criteria Coursework II

| Criteria (100%) | Fail (0-49%) | Pass (50-59%) | Commendation (60-69%) | Distinction (70-100%) |
| :--- | :--- | :--- | :--- | :--- |
| **Problem Definition and Discussion (10%)** | Very limited description of the overall problem was provided, poor justification of why a scalable solution needs to be developed. Limited critical appraisal of the use of scalable technologies. | Solid description of the overall problem was provided, adequate justification presented of why a scalable solution needs to be developed. Solid appraisal of the use of scalable technologies and related patterns. | Very good description of the overall problem with a good justification of why a scalable model needs to be adopted. Strong critical appraisal of the use of scalable technologies, related patterns, and architectural components. | Exemplary description of the overall problem with excellent justification of why a scalable solution needs to be developed. Excellent critical appraisal of the use of scalable technologies, related patterns, and architectural components. |
| **Overview of the technical solution developed (15%)** | The technology used to produce the solution was minimal. Design was poorly informed and did not incorporate many scalable native elements. No meaningful solution architecture was presented. | Limited for the choice of technology applied to the development problem. Clear effort was made to incorporate scalable native components. An architectural diagram of the developed solution was presented. | The technology used to produce the solution was carefully and logically chosen given the development problem. The design was satisfactorily informed by scalable design patterns. A range of scalable components were incorporated into the solution. The solution architecture was documented well incorporating software architecture diagrams. The design of the solution was justified through scalable design patterns. | The technology used to produce the solution was carefully and logically chosen incorporating extensive critical analysis of alternatives given the development problem. The design was satisfactorily informed by a range of extensive scalable design patterns. Alternative technologies were examined and excluded accordingly. A wide range of scalable components were incorporated into the solution. The solution architecture was documented well incorporating control flows and software architecture diagrams. The design of the solution was considered and justified through scalable design patterns. |
| **Application of Advanced Features (20%)** | Minimal or no advanced features were incorporated into the final solution. Potentially, a partial incorporation of a feature has occurred but not fully implemented. | One advanced feature was applied to the solution in a meaningful manner. The application of this feature was justified given the context of the problem and will provide a more compelling experience for end users. | 2 advanced features were applied to the solution in a meaningful manner, providing a more compelling experience for the end users. Incorporation of these features were well justified and integrated with finesse. | 3 or more advanced features were applied to the solution in a meaningful manner, providing a more compelling experience for the end users. Incorporation of these features were well justified and integrated with finesse. |
| **Assessment of Limitations and Scalability (20%)** | The limitations of the solution were not enumerated nor discussed adequately. The solution minimally integrated elements to offer scalable operation. | Some limitations of the solution were discussed with some clear awareness of how to remedy these presented. Scalability was partially catered for in the solution. | A broad appraisal of the limitations of the solution were presented in an informed manner. Scalability was well catered for with multiple scalable elements applied to achieve this. | A broad appraisal of the limitations of the solution were presented Strategies and roadmaps to address these were presented. Scalability was well catered for with multiple scalable elements applied to achieve this. |
| **Concluding comments (5%)** | Limited reflection was applied to the solution, its functionality, limitations and potential applicability. | Sound reflection was applied to the solution, its functionality, limitations, and potential applicability. | Informed reflection was applied to the solution, its functionality, limitations and potential applicability. Weaknesses were identified. | Exemplary reflection was applied to the solution, its functionality, limitations and potential applicability. Weaknesses were identified and improvements were suggested. |
| **Video Demonstration (25%)** | The solution performed poorly or didn't operate at all. There was limited evidence provided of the use of cloud native technologies in a scalable fashion. | The solution functioned moderately well. Implementation issues may have been present but were deemed tolerable. Some evidence of the use of scalable technologies was presented. | The solution performed well and had acceptable implementation issues. Advanced functionality or techniques has been demonstrated. It was evident that the solution leveraged a range of scalable technologies. | The solution performed well and had minimal implementation issues. Advanced techniques or functionality has been demonstrated. It was evident that the solution leveraged a diverse range of scalable technologies. |
| **Referencing (5%)** | Very limited referencing. | Inadequate or incorrect referencing. | Correct and appropriate referencing. | Excellent, correct and appropriate referencing was applied to a high standard. |
