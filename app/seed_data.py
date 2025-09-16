"""Seed data loader for initializing the database with CSV fixtures."""
from __future__ import annotations

import csv
import io
from typing import Iterable, Optional

from sqlmodel import Session, select

from app.models import Curriculum, Journal, Layer, Phase, Strategy
from app.utils import parse_iso_datetime

LAYER_CSV = '''id,color,title,subtitle
0,Strategies,SELF-CARE,(For Surfing)
1,Beige,INHABIT,(Do)
2,Purple,INHABIT,(Feel)
3,Red,EXPRESS,(Do)
4,Blue,EXPRESS,(Feel)
5,Orange,COLLABORATE,(Do)
6,Green,COLLABORATE,(Feel)
7,Yellow,INTEGRATE,(Do)
8,Teal,INTEGRATE,(Feel)
9,Ultraviolet,ABSORB,(Do/Feel)
10,Clear Light,BE,(Neither/Both)
'''

PHASE_CSV = '''id,name
1,Rising
2,Peaking
3,Withdrawal
4,Diminishing
5,Bottoming Out
6,Restoration
'''

CURRICULUM_CSV = '''id,stage_id,phase_id,dosage,expression
1,1,1,Medicinal,Commitment
2,2,1,Medicinal,Inspiration
3,3,1,Medicinal,Leading
4,4,1,Medicinal,Ambition
5,5,1,Medicinal,Hypothesize
6,6,1,Medicinal,Connection
7,7,1,Medicinal,Rebellion
8,8,1,Medicinal,Epiphany
9,9,1,Medicinal,Unification of Mind
10,1,1,Toxic,Overcommitment
11,2,1,Toxic,Grandiosity 
12,3,1,Toxic,Dominating
13,4,1,Toxic,Voraciousness
14,5,1,Toxic,Assert
15,6,1,Toxic,Oversharing
16,7,1,Toxic,Mischief
17,8,1,Toxic,Delusion
18,9,1,Toxic,Worldly Desire
19,1,2,Medicinal,Diligence
20,2,2,Medicinal,Joy
21,3,2,Medicinal,Power-With
22,4,2,Medicinal,Attunement
23,5,2,Medicinal,Experiment
24,6,2,Medicinal,Belonging
25,7,2,Medicinal,Anarchy
26,8,2,Medicinal,Gnosis
27,9,2,Medicinal,Jhana
28,1,2,Toxic,Thriving
29,2,2,Toxic,Ecstasy
30,3,2,Toxic,Power-Over
31,4,2,Toxic,Leprosy
32,5,2,Toxic,Crusade
33,6,2,Toxic,Megalomania
34,7,2,Toxic,Chaos
35,8,2,Toxic,Psychosis
36,9,2,Toxic,Bliss Addiction
37,1,3,Medicinal,Steadiness
38,2,3,Medicinal,Introspectivity
39,3,3,Medicinal,Stepping Back
40,4,3,Medicinal,Humility
41,5,3,Medicinal,Questioning
42,6,3,Medicinal,Boundaries
43,7,3,Medicinal,Reassessment
44,8,3,Medicinal,Openness
45,9,3,Medicinal,Directed Curiosity
46,1,3,Toxic,Indolence
47,2,3,Toxic,Flatness 
48,3,3,Toxic,Cowardice
49,4,3,Toxic,Self-Loathing
50,5,3,Toxic,Suspicion
51,6,3,Toxic,Isolationism
52,7,3,Toxic,Alienation
53,8,3,Toxic,Meaninglessness 
54,9,3,Toxic,Religious Hypocrisy
55,1,4,Medicinal,Recharging
56,2,4,Medicinal,Coziness
57,3,4,Medicinal,Walking Away
58,4,4,Medicinal,Self-Love
59,5,4,Medicinal,Clarity
60,6,4,Medicinal,Connection
61,7,4,Medicinal,Healing
62,8,4,Medicinal,Faith
63,9,4,Medicinal,Soul-Nourishment
64,1,4,Toxic,Numbness
65,2,4,Toxic,Boredom
66,3,4,Toxic,Powerlessness
67,4,4,Toxic,Self-Harm
68,5,4,Toxic,Jealousy
69,6,4,Toxic,Career-ism
70,7,4,Toxic,Anger
71,8,4,Toxic,Cynicism 
72,9,4,Toxic,Dogma
73,1,5,Medicinal,Recovery
74,2,5,Medicinal,Safety
75,3,5,Medicinal,Discernment
76,4,5,Medicinal,Authenticity
77,5,5,Medicinal,Research
78,6,5,Medicinal,Trust
79,7,5,Medicinal,Boundaries
80,8,5,Medicinal,Compassion
81,9,5,Medicinal,Self-Acceptance
82,1,5,Toxic,Rock Bottom
83,2,5,Toxic,Isolation
84,3,5,Toxic,Shame
85,4,5,Toxic,Denial
86,5,5,Toxic,Paralysis
87,6,5,Toxic,Tribalism
88,7,5,Toxic,Hatred
89,8,5,Toxic,Self-Loathing
90,9,5,Toxic,Hopelessness
91,1,6,Medicinal,Rebuilding
92,2,6,Medicinal,Hopefulness
93,3,6,Medicinal,Reassert
94,4,6,Medicinal,Self-Acceptance
95,5,6,Medicinal,Question
96,6,6,Medicinal,Vulnerability
97,7,6,Medicinal,Disintegrate
98,8,6,Medicinal,Pattern-Seeking
99,9,6,Medicinal,Directed Attention
100,1,6,Toxic,New Plan
101,2,6,Toxic,Selfishness
102,3,6,Toxic,Revenge
103,4,6,Toxic,Self-Repression
104,5,6,Toxic,Presume
105,6,6,Toxic,Bitterness
106,7,6,Toxic,The Aftermath
107,8,6,Toxic,Belief Salience
108,9,6,Toxic,Laziness or Lethargy
'''

STRATEGY_CSV = '''id,strategy,layer_id,phase_id
1,Readjusting posture,1,5
2,Getting Comfy,1,5
3,Drinking Water,1,5
4,Listening to Music,2,5
5,Pranayama (Lion's Breath),3,5
6,Learning,5,5
7,One Pushup / One Squat,1,6
8,Wash face,1,6
9,Kirtan,2,6
10,Taking a Bath,2,6
11,Getting Some Sunshine,2,6
12,Somatic Meditation,3,6
13,Biking,3,6
14,Jogging,3,6
15,Dancing,3,6
16,Husband Time,4,6
17,Cold Shower,1,1
18,Clairaudient Practice,2,1
19,Divination,2,1
20,Insight Practice,2,1
21,Activation Breathwork,3,1
22,Competition/Boasting with Friend,5,1
23,Prepare for a Good Conversation,6,1
24,Beginner's Mind,4,1
25,Make Plans,5,1
26,Go on a Walk,3,2
27,Sexy Loving Relationship Stuff,4,2
28,Weightlifting,5,2
29,Pranayama (Skull Shining Breath),5,2
30,Prepare a Meal + Clean Kitchen,6,2
31,Restorative Moment w/ Close Friend,6,2
32,Compassion/Ethics,4,2
33,Networking/Connecting w/ New Folks,6,2
34,Taking solo trampoline time,2,3
35,Scaling back your to-do list,5,3
36,Staying in Crowds,4,3
37,"""I belong here"" Mantra",4,3
38,Tune into Loved Ones' Mood Phases,4,3
39,Intense Exercise,5,3
40,Pranayama (Xanax Breath - 4/7/8),5,3
41,Pranayama (Box Breathing - 4/4/4/4),5,3
42,5-4-3-2-1 Technique,1,3
43,Grounding Exercises,1,3
44,Anti-Anxiety Medication,7,3
45,Long Drives,2,4
46,Hot Beverages,2,4
47,Walking,3,4
48,Journaling,6,4
49,Cleaning,6,4
'''

JOURNAL_CSV = '''id,created_at,user_id,curriculum_id,secondary_curriculum_id,strategy_id
1,2025-09-13T12:34:00.000Z,1,10,11,17.0
2,2025-09-14T10:34:00.000Z,2,24,19,
3,2025-09-15T18:34:00.000Z,1,101,5,10.0
'''


def _parse_optional_int(value: Optional[str]) -> Optional[int]:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except ValueError:
        return int(float(value))


def _load_rows(csv_content: str) -> Iterable[dict[str, str]]:
    reader = csv.DictReader(io.StringIO(csv_content.strip()))
    return list(reader)


def seed_data(session: Session) -> None:
    """Seed all tables if they are currently empty."""

    if session.exec(select(Layer).limit(1)).first() is None:
        _seed_layers(session)
    if session.exec(select(Phase).limit(1)).first() is None:
        _seed_phases(session)
    if session.exec(select(Curriculum).limit(1)).first() is None:
        _seed_curriculum(session)
    if session.exec(select(Strategy).limit(1)).first() is None:
        _seed_strategies(session)
    if session.exec(select(Journal).limit(1)).first() is None:
        _seed_journal(session)


def _seed_layers(session: Session) -> None:
    rows = _load_rows(LAYER_CSV)
    layers = [
        Layer(
            id=int(row["id"]),
            color=row["color"],
            title=row["title"],
            subtitle=row["subtitle"],
        )
        for row in rows
    ]
    session.add_all(layers)
    session.commit()


def _seed_phases(session: Session) -> None:
    rows = _load_rows(PHASE_CSV)
    phases = [
        Phase(
            id=int(row["id"]),
            name=row["name"],
        )
        for row in rows
    ]
    session.add_all(phases)
    session.commit()


def _seed_curriculum(session: Session) -> None:
    rows = _load_rows(CURRICULUM_CSV)
    items = [
        Curriculum(
            id=int(row["id"]),
            stage_id=int(row["stage_id"]),
            phase_id=int(row["phase_id"]),
            dosage=row["dosage"],
            expression=row["expression"],
        )
        for row in rows
    ]
    session.add_all(items)
    session.commit()


def _seed_strategies(session: Session) -> None:
    rows = _load_rows(STRATEGY_CSV)
    strategies = [
        Strategy(
            id=int(row["id"]),
            strategy=row["strategy"],
            layer_id=int(row["layer_id"]),
            phase_id=int(row["phase_id"]),
        )
        for row in rows
    ]
    session.add_all(strategies)
    session.commit()


def _seed_journal(session: Session) -> None:
    rows = _load_rows(JOURNAL_CSV)
    journal_entries = [
        Journal(
            id=int(row["id"]),
            created_at=parse_iso_datetime(row["created_at"]),
            user_id=int(row["user_id"]),
            curriculum_id=int(row["curriculum_id"]),
            secondary_curriculum_id=_parse_optional_int(row["secondary_curriculum_id"]),
            strategy_id=_parse_optional_int(row["strategy_id"]),
        )
        for row in rows
    ]
    session.add_all(journal_entries)
    session.commit()
