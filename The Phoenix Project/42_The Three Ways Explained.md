# The Three Ways Explained

In *The Phoenix Project*, we describe the underpinning principles that all the DevOps patterns can be derived from as “The Three Ways.” It is intended to describe the values and philosophies that guide DevOps processes and practices.

**The First Way** is about the left-to-right flow of work from Development to IT Operations to the customer. In order to maximize flow, we need small batch sizes and intervals of work, never passing defects to downstream work centers, and to constantly optimize for the global goals (as opposed to local goals such as Dev feature completion rates, Test find/fix ratios, or Ops availability measures).

The necessary practices include continuous build, integration, and deployment, creating environments on demand, limiting work in process, and building safe systems and organizations that are safe to change.

**The Second Way** is about the constant flow of fast feedback from right-to-left at all stages of the value stream, amplifying it to ensure that we can prevent problems from happening again or enable faster detection and recovery. By doing this, we create quality at the source, creating or embedding knowledge where we need it.

The necessary practices include “stopping the production line” when our builds and tests fail in the deployment pipeline; constantly elevating the improvement of daily work over daily work; creating fast automated test suites to ensure that code is always in a potentially deployable state; creating shared goals and shared pain between Development and IT Operations; and creating pervasive production telemetry so that everyone can see whether code and environments are operating as designed and that customer goals are being met.

**The Third Way **is about creating a culture that fosters two things: continual experimentation, which requires taking risks and learning from success and failure, and understanding that repetition and practice is the prerequisite to mastery.

Experimentation and risk taking are what enable us to relentlessly improve our system of work, which often requires us to do things very differently than how we’ve done it for decades. And when things go wrong, our constant repetition and daily practice is what allows us to have the skills and habits that enable us to retreat back to a place of safety and resume normal operations.

The necessary practices include creating a culture of innovation and risk taking (as opposed to fear or mindless order taking) and high trust (as opposed to low trust, command-and-control), allocating at least twenty percent of Development and IT Operations cycles towards nonfunctional requirements, and constant reinforcement that improvements are encouraged and celebrated.
