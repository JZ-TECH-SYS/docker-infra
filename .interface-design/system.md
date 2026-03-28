# Design System

## Direction
Project: docker-infra
Personality: Pragmatic, clear, operational
Primary use: dashboards, CRUD screens, admin panels, and client-facing product flows
Avoid: marketing-site hero patterns, decorative gradients, and random visual shifts

## Core Decisions
- Depth: borders-only with subtle surface elevation shifts
- Spacing base: 8px
- Radius scale: 8px, 12px, 16px
- Typography: keep the existing project font stack unless there is a strong product reason to change it
- Density: medium on desktop, comfortable on mobile
- Motion: minimal and purposeful

## Layout Patterns
- Page shell: title, primary action, optional filters, main content region
- Forms: one column on mobile, two columns on desktop unless the data model demands otherwise
- Lists and tables: actions and filters above the content, clear empty and loading states
- Cards: consistent padding, border treatment, and action placement

## Component Rules
- Reuse existing components before inventing new ones
- Keep one depth strategy across the screen
- Use color for meaning, not decoration
- Preserve accessibility, keyboard flow, and responsive behavior

## Update Policy
- Only change this file when a reusable UI pattern changes
- Keep notes short, concrete, and tied to real project usage
